#!/usr/bin/env python3
"""
HWP 파일에서 표(Table) 구조를 추출하는 스크립트.

사용법:
    python hwp_table_extractor.py <hwp_file>

의존성:
    pip install olefile --break-system-packages

참고:
    - 표 셀의 텍스트는 추출 가능하나 정확한 행/열 위치 매핑은 불완전
    - 레벨(level) 정보를 활용해 표 내부 데이터를 구분
"""

import sys
import struct
import zlib
from dataclasses import dataclass
from typing import List, Optional

try:
    import olefile
except ImportError:
    print("❌ olefile 라이브러리가 필요합니다.")
    sys.exit(1)


@dataclass
class TableInfo:
    """표 정보"""
    index: int
    rows: int
    cols: int
    cells: List[str]


def extract_text_from_data(data: bytes) -> str:
    """텍스트 데이터 추출"""
    decoded = ""
    i = 0
    while i < len(data) - 1:
        char_code = struct.unpack('<H', data[i:i+2])[0]
        if char_code == 0:
            break
        elif char_code < 32:
            if char_code in [1,2,3,4,5,6,7,8,11,12,13,14,15,16,17,18,21,22,23]:
                i += 16
                continue
        elif 0x20 <= char_code <= 0xFFFF and not (0xD800 <= char_code <= 0xDFFF):
            decoded += chr(char_code)
        i += 2
    return decoded.strip()


def parse_records(decompressed: bytes) -> list:
    """HWP 레코드 파싱"""
    records = []
    offset = 0
    
    while offset < len(decompressed) - 4:
        header_val = struct.unpack('<I', decompressed[offset:offset+4])[0]
        tag_id = header_val & 0x3FF
        level = (header_val >> 10) & 0x3FF
        size = (header_val >> 20) & 0xFFF
        
        if size == 0xFFF:
            if offset + 8 > len(decompressed):
                break
            size = struct.unpack('<I', decompressed[offset+4:offset+8])[0]
            data_offset = offset + 8
        else:
            data_offset = offset + 4
        
        if data_offset + size > len(decompressed):
            break
            
        data = decompressed[data_offset:data_offset+size]
        records.append({
            'tag': tag_id,
            'level': level,
            'size': size,
            'data': data,
            'offset': offset
        })
        
        offset = data_offset + size
        if offset <= data_offset:
            break
    
    return records


def extract_tables(hwp_path: str) -> List[TableInfo]:
    """HWP 파일에서 표 정보 추출"""
    
    ole = olefile.OleFileIO(hwp_path)
    
    try:
        header = ole.openstream("FileHeader").read()
        is_compressed = header[36] & 1
        
        body_stream = ole.openstream("BodyText/Section0").read()
        
        if is_compressed:
            decompressed = zlib.decompress(body_stream, -15)
        else:
            decompressed = body_stream
        
        records = parse_records(decompressed)
        tables = []
        table_count = 0
        
        # HWPTAG_TABLE (80) 찾기
        for i, rec in enumerate(records):
            if rec['tag'] == 80:  # TABLE
                table_count += 1
                data = rec['data']
                
                if len(data) >= 10:
                    num_rows = struct.unpack('<H', data[4:6])[0]
                    num_cols = struct.unpack('<H', data[6:8])[0]
                    
                    # 표 이후의 텍스트 수집 (다음 표 전까지)
                    cells = []
                    for j in range(i + 1, len(records)):
                        if records[j]['tag'] == 80:  # 다음 표
                            break
                        if records[j]['tag'] == 67:  # PARA_TEXT
                            text = extract_text_from_data(records[j]['data'])
                            if text:
                                cells.append(text)
                    
                    tables.append(TableInfo(
                        index=table_count,
                        rows=num_rows,
                        cols=num_cols,
                        cells=cells
                    ))
        
        # 레벨 기반 표 데이터 추출 (보조)
        level_texts = {}
        for rec in records:
            if rec['tag'] == 67:
                text = extract_text_from_data(rec['data'])
                if text:
                    lvl = rec['level']
                    if lvl not in level_texts:
                        level_texts[lvl] = []
                    level_texts[lvl].append(text)
        
        # Level 2 이상은 표 내부일 가능성 높음
        for lvl in sorted(level_texts.keys()):
            if lvl >= 2 and lvl not in [lvl for t in tables for _ in t.cells]:
                cells = level_texts[lvl]
                if len(cells) > 4:  # 최소 셀 수
                    tables.append(TableInfo(
                        index=len(tables) + 1,
                        rows=0,  # 알 수 없음
                        cols=0,
                        cells=cells
                    ))
        
        return tables
        
    finally:
        ole.close()


def print_table(table: TableInfo):
    """표 정보 출력"""
    print(f"\n📊 표 #{table.index}", end="")
    if table.rows > 0:
        print(f" ({table.rows}행 × {table.cols}열)")
    else:
        print(f" (셀 {len(table.cells)}개)")
    
    print("─" * 60)
    
    if table.rows > 0 and table.cols > 0:
        # 행/열 구조로 출력 시도
        for row_idx in range(min(table.rows, len(table.cells) // max(table.cols, 1))):
            row_cells = table.cells[row_idx * table.cols:(row_idx + 1) * table.cols]
            print("│ " + " │ ".join(f"{c[:15]:<15}" for c in row_cells) + " │")
    else:
        # 셀 목록으로 출력
        for idx, cell in enumerate(table.cells[:20]):
            print(f"  [{idx+1:2d}] {cell[:60]}")
        if len(table.cells) > 20:
            print(f"  ... 외 {len(table.cells) - 20}개 셀")


def main():
    if len(sys.argv) < 2:
        print("사용법: python hwp_table_extractor.py <hwp_file>")
        sys.exit(1)
    
    hwp_path = sys.argv[1]
    
    try:
        tables = extract_tables(hwp_path)
        
        if not tables:
            print("표를 찾을 수 없습니다.")
        else:
            print(f"=== 발견된 표: {len(tables)}개 ===")
            for table in tables:
                print_table(table)
                
    except Exception as e:
        print(f"❌ 오류: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()

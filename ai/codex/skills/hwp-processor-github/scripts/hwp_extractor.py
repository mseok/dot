#!/usr/bin/env python3
"""
HWP 파일에서 텍스트를 추출하는 스크립트.

사용법:
    python hwp_extractor.py <hwp_file> [--output <output_file>]

의존성:
    pip install olefile --break-system-packages
"""

import sys
import argparse
import struct
import zlib

try:
    import olefile
except ImportError:
    print("❌ olefile 라이브러리가 필요합니다.")
    print("   설치: pip install olefile --break-system-packages")
    sys.exit(1)


def extract_text_from_data(data: bytes) -> str:
    """HWP 텍스트 데이터에서 문자열 추출 (UTF-16LE)"""
    decoded = ""
    i = 0
    while i < len(data) - 1:
        char_code = struct.unpack('<H', data[i:i+2])[0]
        if char_code == 0:
            break
        # 컨트롤 코드 처리
        elif char_code < 32:
            # 확장 컨트롤 (16바이트 추가)
            if char_code in [1, 2, 3, 4, 5, 6, 7, 8, 11, 12, 13, 14, 15, 16, 17, 18, 21, 22, 23]:
                i += 16
                continue
            elif char_code == 10:  # 줄바꿈
                decoded += "\n"
            elif char_code == 9:   # 탭
                decoded += "\t"
            i += 2
            continue
        # 유효한 유니코드 문자
        elif 0x20 <= char_code <= 0xFFFF and not (0xD800 <= char_code <= 0xDFFF):
            decoded += chr(char_code)
        i += 2
    return decoded.strip()


def parse_records(decompressed: bytes) -> list:
    """압축 해제된 데이터에서 HWP 레코드 파싱"""
    records = []
    offset = 0
    
    while offset < len(decompressed) - 4:
        header_val = struct.unpack('<I', decompressed[offset:offset+4])[0]
        tag_id = header_val & 0x3FF
        level = (header_val >> 10) & 0x3FF
        size = (header_val >> 20) & 0xFFF
        
        # 확장 크기 처리
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
            'data': data
        })
        
        offset = data_offset + size
        if offset <= data_offset or size < 0:
            break
    
    return records


def extract_hwp_text(hwp_path: str) -> str:
    """HWP 파일에서 전체 텍스트 추출"""
    
    if not olefile.isOleFile(hwp_path):
        raise ValueError(f"유효한 HWP 파일이 아닙니다: {hwp_path}")
    
    ole = olefile.OleFileIO(hwp_path)
    
    try:
        # FileHeader에서 압축 여부 확인
        header = ole.openstream("FileHeader").read()
        is_compressed = header[36] & 1
        
        # BodyText/Section0 읽기
        body_stream = ole.openstream("BodyText/Section0").read()
        
        # 압축 해제
        if is_compressed:
            decompressed = zlib.decompress(body_stream, -15)
        else:
            decompressed = body_stream
        
        # 레코드 파싱
        records = parse_records(decompressed)
        
        # HWPTAG_PARA_TEXT (67) 태그에서 텍스트 추출
        text_parts = []
        for rec in records:
            if rec['tag'] == 67:  # PARA_TEXT
                text = extract_text_from_data(rec['data'])
                if text:
                    text_parts.append(text)
        
        return "\n".join(text_parts)
        
    finally:
        ole.close()


def main():
    parser = argparse.ArgumentParser(
        description='HWP 파일에서 텍스트 추출',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument('hwp_file', help='HWP 파일 경로')
    parser.add_argument('-o', '--output', help='출력 파일 경로 (기본: 표준출력)')
    parser.add_argument('-q', '--quiet', action='store_true', help='메타 정보 숨기기')
    
    args = parser.parse_args()
    
    try:
        text = extract_hwp_text(args.hwp_file)
        
        if args.output:
            with open(args.output, 'w', encoding='utf-8') as f:
                f.write(text)
            if not args.quiet:
                print(f"✅ 저장 완료: {args.output}")
                print(f"   추출된 글자 수: {len(text):,}자")
        else:
            print(text)
            
    except FileNotFoundError:
        print(f"❌ 파일을 찾을 수 없습니다: {args.hwp_file}", file=sys.stderr)
        sys.exit(1)
    except ValueError as e:
        print(f"❌ {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"❌ 오류 발생: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()

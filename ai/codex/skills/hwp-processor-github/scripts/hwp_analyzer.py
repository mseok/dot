#!/usr/bin/env python3
"""
HWP 파일 구조를 분석하는 스크립트.

사용법:
    python hwp_analyzer.py <hwp_file>

출력:
    - OLE2 스트림 구조
    - 압축 정보
    - 레코드 태그 통계
    - 이미지 목록
"""

import sys
import struct
import zlib
from collections import Counter

try:
    import olefile
except ImportError:
    print("❌ olefile 필요: pip install olefile --break-system-packages")
    sys.exit(1)


# HWP 태그 이름 매핑
TAG_NAMES = {
    16: "DOCUMENT_PROPERTIES",
    17: "ID_MAPPINGS", 
    18: "BIN_DATA",
    19: "FACE_NAME",
    20: "BORDER_FILL",
    21: "CHAR_SHAPE",
    22: "TAB_DEF",
    23: "NUMBERING",
    24: "BULLET",
    25: "PARA_SHAPE",
    26: "STYLE",
    27: "DOC_DATA",
    28: "DISTRIBUTE_DOC_DATA",
    64: "PARA_HEADER",
    65: "PARA_TEXT_OLD",
    66: "LIST_HEADER",
    67: "PARA_TEXT",
    68: "PARA_CHAR_SHAPE",
    69: "PARA_LINE_SEG",
    70: "PARA_RANGE_TAG",
    71: "CTRL_HEADER",
    72: "PAGE_DEF",
    73: "FOOTNOTE_SHAPE",
    74: "PAGE_BORDER_FILL",
    75: "SHAPE_COMPONENT",
    76: "TABLE_OLD",
    77: "SHAPE_COMPONENT_LINE",
    78: "SHAPE_COMPONENT_RECT",
    79: "SHAPE_COMPONENT_ELLIPSE",
    80: "TABLE",
    81: "CELL",
    82: "SHAPE_COMPONENT_OLE",
    83: "SHAPE_COMPONENT_PICTURE",
    84: "SHAPE_COMPONENT_CONTAINER",
    85: "CTRL_DATA",
}


def analyze_hwp(hwp_path: str):
    """HWP 파일 구조 분석"""
    
    if not olefile.isOleFile(hwp_path):
        print(f"❌ 유효한 HWP 파일이 아닙니다: {hwp_path}")
        return
    
    ole = olefile.OleFileIO(hwp_path)
    
    print("=" * 60)
    print(f"📄 HWP 파일 분석: {hwp_path}")
    print("=" * 60)
    
    # 1. OLE2 스트림 구조
    print("\n📁 OLE2 스트림 구조")
    print("-" * 40)
    
    images = []
    for entry in ole.listdir():
        stream_path = "/".join(entry)
        try:
            size = ole.get_size(stream_path)
            print(f"  {stream_path:<30} {size:>10,} bytes")
            
            if stream_path.startswith("BinData/"):
                images.append((stream_path, size))
        except:
            print(f"  {stream_path}")
    
    # 2. FileHeader 분석
    print("\n📋 파일 헤더 정보")
    print("-" * 40)
    
    header = ole.openstream("FileHeader").read()
    signature = header[:32].decode('utf-8', errors='ignore').rstrip('\x00')
    version = f"{header[32]}.{header[33]}.{header[34]}.{header[35]}"
    flags = header[36:40]
    
    is_compressed = bool(flags[0] & 1)
    is_encrypted = bool(flags[0] & 2)
    is_distributed = bool(flags[0] & 4)
    is_script = bool(flags[0] & 8)
    
    print(f"  시그니처: {signature}")
    print(f"  버전: {version}")
    print(f"  압축: {'예' if is_compressed else '아니오'}")
    print(f"  암호화: {'예' if is_encrypted else '아니오'}")
    print(f"  배포용: {'예' if is_distributed else '아니오'}")
    print(f"  스크립트: {'예' if is_script else '아니오'}")
    
    # 3. BodyText 분석
    print("\n📝 본문 분석")
    print("-" * 40)
    
    body_stream = ole.openstream("BodyText/Section0").read()
    print(f"  원본 크기: {len(body_stream):,} bytes")
    
    if is_compressed:
        try:
            decompressed = zlib.decompress(body_stream, -15)
            ratio = len(body_stream) / len(decompressed) * 100
            print(f"  압축 해제 후: {len(decompressed):,} bytes")
            print(f"  압축률: {ratio:.1f}%")
        except zlib.error as e:
            print(f"  ❌ 압축 해제 실패: {e}")
            decompressed = None
    else:
        decompressed = body_stream
    
    # 4. 레코드 태그 통계
    if decompressed:
        print("\n📊 레코드 태그 통계")
        print("-" * 40)
        
        tag_counter = Counter()
        offset = 0
        record_count = 0
        
        while offset < len(decompressed) - 4:
            header_val = struct.unpack('<I', decompressed[offset:offset+4])[0]
            tag_id = header_val & 0x3FF
            size = (header_val >> 20) & 0xFFF
            
            if size == 0xFFF:
                if offset + 8 > len(decompressed):
                    break
                size = struct.unpack('<I', decompressed[offset+4:offset+8])[0]
                offset += 8
            else:
                offset += 4
            
            tag_counter[tag_id] += 1
            record_count += 1
            offset += size
            
            if offset <= 0 or size < 0:
                break
        
        print(f"  총 레코드 수: {record_count:,}개")
        print()
        
        for tag_id, count in tag_counter.most_common(15):
            tag_name = TAG_NAMES.get(tag_id, f"TAG_{tag_id}")
            print(f"  {tag_name:<25} {count:>6}개")
    
    # 5. 이미지 목록
    if images:
        print("\n🖼️ 포함된 이미지")
        print("-" * 40)
        for path, size in images:
            ext = path.split('.')[-1].upper() if '.' in path else "?"
            print(f"  {path:<30} [{ext}] {size:>10,} bytes")
    
    # 6. 미리보기 텍스트
    if ole.exists("PrvText"):
        print("\n👁️ 미리보기 텍스트 (처음 500자)")
        print("-" * 40)
        prv_text = ole.openstream("PrvText").read()
        try:
            preview = prv_text.decode('utf-16-le', errors='ignore')[:500]
            print(f"  {preview}...")
        except:
            print("  (디코딩 실패)")
    
    ole.close()
    print("\n" + "=" * 60)


def main():
    if len(sys.argv) < 2:
        print("사용법: python hwp_analyzer.py <hwp_file>")
        sys.exit(1)
    
    analyze_hwp(sys.argv[1])


if __name__ == "__main__":
    main()

---
name: hwp-processor
description: HWP(한글) 파일 텍스트 추출, 분석, 표 파싱 도구. 사용자가 HWP 파일을 업로드하고 내용 추출, 요약, 번역, 분석을 요청할 때 사용. OLE2 컨테이너 구조 분석, zlib 압축 해제, HWP 레코드 파싱을 통한 텍스트/표 추출 지원. 정부지원사업 서류, 공문서, 보고서 등 한국어 HWP 문서 작업에 최적화.
---

# HWP Processor

한글(HWP) 파일에서 텍스트와 표를 추출하는 skill.

## 빠른 시작

### 방법 1: pyhwp 사용 (권장)

```bash
pip install pyhwp olefile --break-system-packages
hwp5txt "파일명.hwp"
```

### 방법 2: 자체 파서 스크립트 사용

```bash
python scripts/hwp_extractor.py "파일명.hwp"
```

## HWP 파일 구조

```
HWP 파일 (OLE2 컨테이너)
├── FileHeader          # 파일 헤더 (압축 여부 플래그)
├── DocInfo             # 문서 정보
├── BodyText/
│   └── Section0        # 본문 (zlib 압축)
├── BinData/            # 이미지 파일들
│   ├── BIN0001.BMP
│   └── BIN0002.JPG
└── PrvText             # 미리보기 텍스트
```

## 핵심 처리 단계

1. **OLE2 컨테이너 열기**: `olefile.OleFileIO()`
2. **압축 해제**: `zlib.decompress(data, -15)` (raw deflate)
3. **레코드 파싱**: 4바이트 헤더 (TagID 10bit, Level 10bit, Size 12bit)
4. **텍스트 추출**: HWPTAG_PARA_TEXT(67) 태그에서 UTF-16LE 디코딩

## 주요 HWP 태그

| TagID | 이름 | 용도 |
|-------|------|------|
| 64 | PARA_HEADER | 문단 헤더 |
| 66 | LIST_HEADER | 리스트/표 셀 |
| 67 | PARA_TEXT | 문단 텍스트 |
| 71 | CTRL_HEADER | 컨트롤 (표, 그림 등) |
| 80 | TABLE | 표 정의 |

## 스크립트

- `scripts/hwp_extractor.py`: 전체 텍스트 추출
- `scripts/hwp_table_extractor.py`: 표 구조 추출
- `scripts/hwp_analyzer.py`: 문서 구조 분석

## 한계점

- **표 셀 위치**: 텍스트는 추출되나 정확한 행/열 매핑 불완전
- **셀 병합**: rowspan/colspan 처리 어려움
- **그래프/차트**: OLE 임베딩 객체 해석 필요
- **서식 정보**: 글꼴, 색상 등 스타일 정보 미추출

## AI 서비스별 HWP 지원 비교

| AI | 직접 지원 | 방법 |
|----|----------|------|
| **Gemini** | ✅ 가능 | 파일 업로드 → 바로 분석 |
| **Claude** | ❌ 불가 | 이 skill로 텍스트 추출 |
| **ChatGPT** | ❌ 불가 | 외부 GPTs 앱 필요 |

## 참고 자료

- HWP 5.0 파일 구조: `references/hwp_structure.md`
- 한글과컴퓨터 공식 문서: HWPX 개방형 포맷 (2021~)

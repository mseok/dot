# 🇰🇷 HWP Processor

**한글(HWP) 파일에서 텍스트와 표를 추출하는 Python 도구**

[![Python](https://img.shields.io/badge/Python-3.8+-blue.svg)](https://www.python.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 📋 개요

HWP(Hangul Word Processor)는 한국에서 가장 널리 사용되는 문서 포맷이지만, 독자적인 바이너리 구조로 인해 다른 프로그램에서 읽기 어렵습니다. 이 프로젝트는 HWP 파일의 OLE2 컨테이너 구조를 분석하여 텍스트와 표 데이터를 추출합니다.

### ✨ 주요 기능

- **텍스트 추출**: HWP 파일에서 전체 텍스트 추출
- **표 데이터 추출**: 표 구조 감지 및 셀 내용 추출
- **문서 분석**: 파일 구조, 이미지 목록, 레코드 통계 확인
- **Claude AI Skill**: Anthropic Claude와 통합하여 사용 가능

## 🚀 설치

### 요구사항

- Python 3.8 이상
- olefile 라이브러리

### 설치 방법

```bash
# 저장소 클론
git clone https://github.com/YOUR_USERNAME/hwp-processor.git
cd hwp-processor

# 의존성 설치
pip install -r requirements.txt
```

## 📖 사용법

### 1. 텍스트 추출

```bash
# 표준 출력으로 텍스트 추출
python scripts/hwp_extractor.py 문서.hwp

# 파일로 저장
python scripts/hwp_extractor.py 문서.hwp -o 출력.txt
```

### 2. 표 데이터 추출

```bash
python scripts/hwp_table_extractor.py 문서.hwp
```

출력 예시:
```
=== 발견된 표: 3개 ===

📊 표 #1 (5행 × 4열)
────────────────────────────────────────
  [ 1] 구분
  [ 2] 2024년
  [ 3] 2025년
  [ 4] 증감
  ...
```

### 3. 문서 구조 분석

```bash
python scripts/hwp_analyzer.py 문서.hwp
```

출력 예시:
```
📄 HWP 파일 분석: 문서.hwp
============================================================

📁 OLE2 스트림 구조
----------------------------------------
  FileHeader                            256 bytes
  BodyText/Section0                  68,707 bytes
  BinData/BIN0001.JPG                38,663 bytes
  ...

📋 파일 헤더 정보
----------------------------------------
  시그니처: HWP Document File
  버전: 5.1.1.0
  압축: 예
  암호화: 아니오
```

### 4. Python 모듈로 사용

```python
from scripts.hwp_extractor import extract_hwp_text

# 텍스트 추출
text = extract_hwp_text("문서.hwp")
print(text)
```

## 🔧 HWP 파일 구조

```
HWP 파일 (OLE2 컨테이너)
├── FileHeader          # 파일 헤더 (압축/암호화 플래그)
├── DocInfo             # 문서 정보 (글꼴, 스타일)
├── BodyText/
│   └── Section0        # 본문 (zlib 압축)
├── BinData/            # 첨부 이미지
└── PrvText             # 미리보기 텍스트
```

자세한 구조는 [references/hwp_structure.md](references/hwp_structure.md) 참조.

## 🤖 Claude AI Skill로 사용

이 프로젝트는 [Anthropic Claude](https://claude.ai)의 Skill로 사용할 수 있습니다.

1. `hwp-processor.skill` 파일 다운로드
2. Claude 설정에서 Skill 추가
3. HWP 파일 업로드 후 분석 요청

## ⚠️ 제한사항

| 기능 | 상태 | 설명 |
|------|------|------|
| 텍스트 추출 | ✅ 완전 지원 | UTF-16LE 디코딩 |
| 표 감지 | ✅ 지원 | 표 존재 여부 및 크기 |
| 표 셀 텍스트 | ⚠️ 부분 지원 | 텍스트는 추출되나 행/열 위치 불완전 |
| 셀 병합 | ❌ 미지원 | rowspan/colspan 처리 어려움 |
| 이미지 추출 | ⚠️ 부분 지원 | BinData에서 원본 파일 추출 가능 |
| 차트/그래프 | ❌ 미지원 | OLE 임베딩 객체 해석 필요 |
| 서식 정보 | ❌ 미지원 | 글꼴, 색상 등 스타일 미추출 |
| 암호화 문서 | ❌ 미지원 | 암호 해제 불가 |
| HWPX 포맷 | ❌ 미지원 | 개방형 포맷은 별도 처리 필요 |

## 🔬 AI 서비스별 HWP 지원 비교

| AI 서비스 | 직접 지원 | 방법 |
|-----------|----------|------|
| **Google Gemini** | ✅ 가능 | 파일 업로드 → 바로 분석 |
| **Claude** | ❌ 불가 | 이 도구로 텍스트 추출 후 분석 |
| **ChatGPT** | ❌ 불가 | 외부 GPTs 앱 또는 변환 필요 |

## 🤝 기여하기

기여를 환영합니다! 다음과 같은 방식으로 참여할 수 있습니다:

1. 🐛 버그 리포트: [Issues](https://github.com/YOUR_USERNAME/hwp-processor/issues)
2. 💡 기능 제안: [Issues](https://github.com/YOUR_USERNAME/hwp-processor/issues)
3. 🔧 Pull Request: Fork 후 PR 제출

### 개발 환경 설정

```bash
git clone https://github.com/YOUR_USERNAME/hwp-processor.git
cd hwp-processor
pip install -r requirements.txt

# 테스트 실행
python scripts/hwp_extractor.py test_files/sample.hwp
```

## 📚 참고 자료

- [pyhwp](https://github.com/mete0r/pyhwp) - Python HWP 라이브러리
- [olefile](https://github.com/decalage2/olefile) - OLE2 파일 파서
- [한글과컴퓨터 HWPX 공개](https://www.hancom.com) - 개방형 포맷 문서

## 📄 라이선스

이 프로젝트는 [MIT 라이선스](LICENSE)를 따릅니다.

## 👤 만든 사람

- 자유스콜레 (Free Schole) - [@ejang](https://github.com/ejang)

---

⭐ 이 프로젝트가 도움이 되셨다면 Star를 눌러주세요!

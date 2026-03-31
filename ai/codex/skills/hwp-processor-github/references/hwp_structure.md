# HWP 5.0 파일 구조 참조 문서

## 개요

HWP(Hangul Word Processor)는 한글과컴퓨터의 독자 문서 포맷.
HWP 5.0 이상은 OLE2 컴파운드 파일 형식 사용.

## OLE2 컨테이너 구조

```
HWP 파일
├── FileHeader (256 bytes)
│   ├── 시그니처 (32 bytes): "HWP Document File"
│   ├── 버전 (4 bytes): Major.Minor.Micro.Extra
│   └── 플래그 (4 bytes): 압축, 암호화, 배포용, 스크립트
│
├── DocInfo (가변)
│   └── 문서 속성, 글꼴, 스타일 등
│
├── BodyText/
│   ├── Section0 (본문 섹션 1)
│   ├── Section1 (본문 섹션 2)
│   └── ...
│
├── BinData/
│   ├── BIN0001.* (첨부 이미지/OLE 객체)
│   ├── BIN0002.*
│   └── ...
│
├── PrvText (2044 bytes)
│   └── 미리보기 텍스트 (UTF-16LE)
│
├── PrvImage
│   └── 미리보기 이미지 (PNG)
│
├── DocOptions/
│   └── _LinkDoc 등
│
└── Scripts/
    ├── DefaultJScript
    └── JScriptVersion
```

## FileHeader 구조 (256 bytes)

| 오프셋 | 크기 | 설명 |
|--------|------|------|
| 0 | 32 | 시그니처: "HWP Document File" |
| 32 | 4 | 버전: [Major][Minor][Micro][Extra] |
| 36 | 4 | 플래그 (비트마스크) |
| 40 | 216 | 예약 |

### 플래그 비트

| 비트 | 의미 |
|------|------|
| 0 | 압축 여부 |
| 1 | 암호화 여부 |
| 2 | 배포용 문서 |
| 3 | 스크립트 저장 |
| 4 | DRM 보안 |
| 5 | XMLTemplate 저장 |
| 6 | 문서 이력 |
| 7 | 전자 서명 |
| 8 | 공인 인증서 암호화 |
| 9 | 전자 서명 예비 |
| 10 | 공인 인증서 DRM |
| 11 | CCL 문서 |

## 레코드 구조

BodyText의 각 Section은 레코드 시퀀스로 구성.

### 레코드 헤더 (4 bytes)

```
┌─────────────────────────────────────────────────┐
│  Size (12bit) │ Level (10bit) │ TagID (10bit)  │
└─────────────────────────────────────────────────┘
   [31:20]          [19:10]          [9:0]
```

- **TagID**: 레코드 유형 (0-1023)
- **Level**: 중첩 레벨 (0-1023)
- **Size**: 데이터 크기 (0-4094, 4095면 확장)

### 확장 크기

Size = 0xFFF (4095)이면 다음 4바이트가 실제 크기.

## 주요 태그 ID

### 문서 정보 태그 (DocInfo)

| TagID | 이름 | 설명 |
|-------|------|------|
| 16 | DOCUMENT_PROPERTIES | 문서 속성 |
| 17 | ID_MAPPINGS | ID 매핑 테이블 |
| 18 | BIN_DATA | 바이너리 데이터 정보 |
| 19 | FACE_NAME | 글꼴 이름 |
| 20 | BORDER_FILL | 테두리/채우기 |
| 21 | CHAR_SHAPE | 글자 모양 |
| 22 | TAB_DEF | 탭 정의 |
| 23 | NUMBERING | 번호 매기기 |
| 24 | BULLET | 글머리표 |
| 25 | PARA_SHAPE | 문단 모양 |
| 26 | STYLE | 스타일 |

### 본문 태그 (BodyText)

| TagID | 이름 | 설명 |
|-------|------|------|
| 64 | PARA_HEADER | 문단 헤더 |
| 66 | LIST_HEADER | 리스트/셀 헤더 |
| 67 | PARA_TEXT | 문단 텍스트 ⭐ |
| 68 | PARA_CHAR_SHAPE | 문단 내 글자 모양 |
| 69 | PARA_LINE_SEG | 줄 나눔 정보 |
| 70 | PARA_RANGE_TAG | 범위 태그 |
| 71 | CTRL_HEADER | 컨트롤 헤더 ⭐ |
| 72 | PAGE_DEF | 페이지 정의 |
| 80 | TABLE | 표 정의 ⭐ |
| 81 | CELL | 셀 정의 |

## PARA_TEXT (67) 구조

문단 텍스트는 UTF-16LE 인코딩.

### 컨트롤 코드

| 코드 | 길이 | 설명 |
|------|------|------|
| 0 | - | 문자열 종료 |
| 1 | 16 | 예약 |
| 2 | 16 | 구역/단 정의 |
| 3 | 16 | 필드 시작 |
| 4 | 16 | 필드 끝 |
| 9 | 2 | 탭 |
| 10 | 2 | 줄 바꿈 |
| 11 | 16 | 그리기 객체 |
| 12 | 16 | 예약 |
| 13 | 16 | 하이픈 |
| 14 | 16 | 예약 |
| 15 | 16 | 숨은 설명 |
| 16 | 16 | 머리말/꼬리말 |
| 17 | 16 | 각주/미주 |
| 18 | 16 | 자동 번호 |
| 21 | 16 | 페이지 컨트롤 |
| 22 | 16 | 책갈피/하이퍼링크 |
| 23 | 16 | 덧말/글자 겹침 |

### 텍스트 추출 알고리즘

```python
def extract_text(data):
    result = ""
    i = 0
    while i < len(data) - 1:
        char_code = struct.unpack('<H', data[i:i+2])[0]
        
        if char_code == 0:
            break
        elif char_code < 32:
            # 확장 컨트롤 (16바이트)
            if char_code in [1,2,3,4,5,6,7,8,11,12,13,14,15,16,17,18,21,22,23]:
                i += 16
                continue
            elif char_code == 10:
                result += "\n"
            elif char_code == 9:
                result += "\t"
            i += 2
        else:
            # 일반 문자
            result += chr(char_code)
            i += 2
    
    return result
```

## TABLE (80) 구조

| 오프셋 | 크기 | 설명 |
|--------|------|------|
| 0 | 4 | 플래그 |
| 4 | 2 | 행 수 |
| 6 | 2 | 열 수 |
| 8 | 2 | 셀 간격 |
| 10 | 2*5 | 여백 (좌/우/상/하/테두리) |
| 20 | 가변 | 행 높이 배열 |

## 압축

BodyText 섹션은 zlib raw deflate로 압축.

```python
import zlib
decompressed = zlib.decompress(compressed_data, -15)
```

- wbits = -15: raw deflate (헤더 없음)
- 일반적으로 70-80% 압축률

## HWPX 포맷 (개방형)

2021년부터 한글과컴퓨터가 기본 포맷으로 전환.

- ZIP 컨테이너
- XML 기반 내부 구조
- ODF(Open Document Format)와 유사
- 표준 문서: [한글과컴퓨터 개발자 센터](https://www.hancom.com/etc/hwpDownload.do)

## 참고 자료

- pyhwp 라이브러리: https://github.com/mete0r/pyhwp
- olefile 라이브러리: https://github.com/decalage2/olefile
- HWP 파일 포맷 분석: https://www.hancom.com

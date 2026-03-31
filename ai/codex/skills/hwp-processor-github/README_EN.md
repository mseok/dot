# 🇰🇷 HWP Processor

**Extract text and tables from Korean HWP (Hangul Word Processor) files**

[![Python](https://img.shields.io/badge/Python-3.8+-blue.svg)](https://www.python.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[한국어 README](README.md)

## Overview

HWP (Hangul Word Processor) is the most widely used document format in South Korea, but its proprietary binary structure makes it difficult to read with other programs. This project analyzes the OLE2 container structure of HWP files to extract text and table data.

### Features

- **Text Extraction**: Extract full text from HWP files
- **Table Extraction**: Detect table structures and extract cell contents
- **Document Analysis**: View file structure, image list, record statistics
- **Claude AI Skill**: Can be integrated with Anthropic Claude

## Installation

```bash
git clone https://github.com/YOUR_USERNAME/hwp-processor.git
cd hwp-processor
pip install -r requirements.txt
```

## Usage

### Extract Text

```bash
python scripts/hwp_extractor.py document.hwp -o output.txt
```

### Extract Tables

```bash
python scripts/hwp_table_extractor.py document.hwp
```

### Analyze Document Structure

```bash
python scripts/hwp_analyzer.py document.hwp
```

## HWP File Structure

```
HWP File (OLE2 Container)
├── FileHeader          # File header (compression/encryption flags)
├── DocInfo             # Document info (fonts, styles)
├── BodyText/
│   └── Section0        # Body text (zlib compressed)
├── BinData/            # Embedded images
└── PrvText             # Preview text
```

## Limitations

- ✅ Text extraction: Fully supported
- ⚠️ Table cells: Text extracted but row/column mapping incomplete
- ❌ Cell merging: Not supported
- ❌ Charts/Graphs: Not supported
- ❌ Encrypted documents: Not supported
- ❌ HWPX format: Not supported (different format)

## License

[MIT License](LICENSE)

## Author

- Free Schole (자유스콜레) - [@freeschole](https://github.com/freeschole)

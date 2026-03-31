---
name: single-paper-review
description: >
  Use when "논문 리뷰", "논문 정리", single-paper deep summary 요청에서
  본문 figure를 `Attachments/`에 저장하고 한 note 안에 모두 embed한
  Obsidian 친화적 한국어 단일 논문 정리 노트가 필요할 때. 방법을
  우선적으로 강조하면서 결과/지표 정의와 재사용 가능한 figure/table
  anchor를 포함한 문서를 만든다.
---

# Single Paper Review

이 스킬은 다음 성질을 가진 단일 논문 정리 노트를 만든다.
- Obsidian 친화적인 Markdown (`YAML frontmatter + headings`)
- 채택/거절 관점의 review가 아니라 방법과 결과 중심의 정리
- 기본 요약 비중은 background보다 method에 더 크게 둔다.
- 지표를 수식과 해석까지 포함해 설명하는 metric-literate 문서
- 다른 노트에서 재사용할 수 있도록 핵심 figure/table anchor를 남기는 문서
- main paper body에 등장하는 모든 Figure를 한 note 안에서 바로 볼 수 있게 embed하는 문서

## 템플릿 사용
- 기본 템플릿: `assets/review_template.md`
- 볼트 안에 `Templates/Single Paper Review Template.md`가 있으면 그것을 사용해도 된다.
- 단, 두 템플릿의 구조는 동일해야 한다.

## 작업 순서
1. 대상 note 경로를 먼저 고정한다.
   - 사용자가 특정 `.md` 파일을 주면 그 파일을 업데이트한다.
   - 그렇지 않으면 논문 제목을 기반으로 새 note를 만든다.
   - 파일명은 사용자가 이미 링크한 경로가 있으면 그 경로를 유지한다.

2. 본문 figure inventory를 먼저 확정한다.
   - 최소 집합은 main paper body에서 번호가 붙은 모든 Figure다. 즉, 본문에 등장하는 Figure 1..N은 빠짐없이 다룬다.
   - Supplementary/Appendix figure는 사용자가 요청하거나 method/result 이해에 꼭 필요할 때만 추가한다.
   - 각 figure는 원 figure 단위의 PNG로 캡처해 `Attachments/<paper-slug>/`에 저장한다.
   - 패널별 crop은 가독성 보조용으로만 추가할 수 있고, 원 figure embed를 대체하면 안 된다.
   - note에는 figure를 논문 순서대로 모두 모아 보는 전용 섹션을 반드시 둔다.

3. frontmatter는 최소하지만 정확하게 채운다.
   - `author`, `venue`, `year`, `url`은 기본으로 넣는다.
   - 가능하면 `doi`, `arxiv`, `code`, `aliases`를 함께 채운다.
   - 사용자가 달리 요청하지 않으면 `categories: [[Papers]]`를 유지한다.
   - note 본문은 한국어로 쓰되, frontmatter key는 English를 유지한다.

4. 논문 요약은 "정리" 관점으로 쓴다.
   - `TL;DR`: 메커니즘과 headline result 위주로 2-5문장.
   - `한 줄 기여`: prior work 대비 무엇이 달라졌는지 claim 형태로 3-5개.
   - `문제 설정`: task, input/output, 가정, 기존 방식이 어디서 깨지는지 명확히 쓴다.
   - 지면이 제한되면 background/related work 요약을 줄이고 method novelty와 design choice를 우선 설명한다.

5. 방법은 재구현 방향을 이해할 수 있을 정도로 쓴다.
   - 먼저 high-level pipeline을 쓰고, 그 다음 핵심 구성요소를 푼다.
   - 가능하면 각 구성요소마다 "무엇을 넣고 무엇이 나오며 왜 필요한지"를 함께 쓴다.
   - ambiguity를 줄이는 데 도움이 되면 notation과 shape를 명시한다.
   - 핵심 loss, objective, sampling, inference procedure가 있으면 빠뜨리지 않는다.
   - prior method와 달라지는 지점을 architecture, training signal, data flow 수준에서 분리해 적는다.
   - 논문에 algorithm box가 있으면 그대로 복사하지 말고 짧은 pseudo-step으로 다시 쓴다.

6. `지표 (수식 + 의미)` 섹션은 반드시 넣는다.
   - Methods/Results에서 실제로 쓰인 모든 핵심 metric마다 아래를 적는다.
   - LaTeX 수식 정의 (`$$ ... $$` for block equation, `$ ... $` for inline equation)
   - 이 논문에서의 계산 방식
   - metric이 실제로 의미하는 바와 해석상 함정
   - LaTeX에서는 single `\`만 사용한다.
   - 텍스트에서 `\<`, `\>`처럼 꺾쇠를 그대로 쓰고 싶으면 escape한다.

7. 실험은 `figure/table anchor` 중심으로 쓴다.
   - 중요한 claim을 plain language로 먼저 쓴다.
   - 바로 뒤에 정확한 Figure/Table 번호와 reported number를 붙인다.
   - exhaustive listing보다 의사결정에 중요한 결과를 우선한다.
   - 다만 별도의 `본문 그림 모음` 섹션에서는 중요도와 무관하게 main paper body figure 전부를 논문 순서대로 embed한다.

8. 결과는 재사용 가능하게 남긴다.
   - attachment folder는 `Attachments/<paper-slug>/`를 기본으로 한다.
   - 본문 Figure는 `fig-1.png`, `fig-2.png`처럼 Figure 번호를 보존하는 파일명으로 저장한다.
   - `본문 그림 모음` 섹션은 필수다. 이 섹션만 보면 본문 Figure를 전부 훑을 수 있어야 한다.
   - figure: 본문에 등장하는 모든 Figure의 PNG를 저장하고 note에 embed한다.
   - table: 단순하면 Markdown table로 옮기고, 복잡하면 이미지로 embed한다.
   - `재사용 가능한 그림 / 표` 섹션은 exhaustive atlas가 아니라, 특히 다시 인용할 가치가 큰 anchor만 추려서 적는다.
   - 각 figure/table에는 항상 다음을 적는다.
     - 출처: Figure/Table 번호 + page
     - 왜 중요한가: 어떤 결론을 지지하는가
     - 어떻게 읽는가: 축, 범례, 비교 포인트
   - 본문 Figure를 모두 확보하지 못했으면 누락된 Figure 번호와 이유를 note에 명시한다.

## 출력 규칙
- note prose는 한국어로 쓴다.
- metric 이름, model 이름, dataset 이름은 원 논문 표기를 보존한다.
- figure/table anchor는 가능한 한 exact number를 유지한다.
- 사용자가 별도 요청을 하지 않아도 method 관련 설명 밀도를 더 높게 유지한다.
- code 실행을 전제로 한 검증 서술은 쓰지 않는다.
- main paper body의 Figure는 빠짐없이 embed한다.
- 한 note 안에 `본문 그림 모음` 섹션을 두고 Figure를 논문 순서대로 정렬한다.
- supplementary/appendix figure를 생략했으면 생략 사실을 명시한다.

## 제약
- note를 PDF로 변환하는 절차는 넣지 않는다.
- 새 schematic/diagram figure를 직접 만드는 절차는 넣지 않는다.
- 본문은 한국어로 쓰되 따옴표는 가능하면 ASCII `" "`를 사용한다.

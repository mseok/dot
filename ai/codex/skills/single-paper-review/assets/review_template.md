---
author:
venue:
year:
url:
doi:
arxiv:
code:
keywords:
categories:
  - "[[Papers]]"
aliases:
---

## TL;DR
[2-5문장. 무엇이 문제였는지, 핵심 아이디어가 무엇인지, headline result가 무엇인지, 무엇을 기억해야 하는지 적는다.]

## 한 줄 기여
1. [기여 1]
2. [기여 2]
3. [기여 3]

## 문제 설정
- **Task**: [무엇을 예측/생성/최적화하는가?]
- **Inputs/outputs**: [필요하면 notation과 shape까지]
- **Assumptions**: [데이터, 제약, prior]
- **왜 필요한가 / 기존 방식은 어디서 깨지는가**: [failure mode 또는 gap]

## 방법 개요
[5-10줄 정도로 전체 pipeline을 설명한다. 필요하면 텍스트 기반 mini diagram을 포함한다.]

## 방법 상세
### 핵심 구성요소
- [Module A: 무엇을 하는지, 어떤 수식/설계를 쓰는지]
- [Module B: ...]

### 학습 / 최적화
- **Objective**: [loss, regularizer]
- **Data**: [dataset, preprocessing]
- **Compute**: [논문에 나오면 GPU/TPU, steps, batch size]
- **Hyperparameters**: [핵심 것만]

## 지표 (수식 + 의미)
Methods/Results에서 핵심적으로 쓰인 metric마다 다음 세 가지를 적는다.
1. 수식 정의
2. 이 논문에서의 계산 방식
3. 해석과 함정

### Metric: [Name]
- **정의**:
  $$[Put the formula here]$$
- **이 논문에서는 이렇게 계산**:
  - [Averaging: per-sample / per-class / micro vs macro]
  - [Threshold, matching rule, postprocessing]
  - [Confidence interval / seed / repeat]
- **해석**:
  - [값이 높거나 낮을 때 무엇을 뜻하는가]
  - [어떤 요인에 민감한가]
  - [언제 misleading할 수 있는가]

## 실험
### 실험 설정
- **Datasets**: [이름, 크기, split]
- **Baselines**: [왜 중요한 baseline인지]
- **Evaluation protocol**: [single-run / multi-run / tuning rule]

### 핵심 결과
- [중요한 claim을 plain language로 쓴 뒤, 정확한 table/figure ref를 붙인다.]
- [가능하면 absolute number와 baseline 대비 delta를 같이 적는다.]

### Ablation 및 추가 분석
- [무엇을 바꿨는지, 기대 효과가 무엇인지, 실제로 무엇이 일어났는지]

### 정성 분석
- [그림이 무엇을 보여주는지, 무엇을 봐야 하는지]

## 재사용 가능한 그림 / 표
핵심 결과 figure/table을 다른 note에서도 재사용할 수 있게 정리한다.

### 그림
![Fig. X: Caption](Attachments/[paper-slug]/fig-x.png)
- **출처**: Paper Figure X (page Y)
- **왜 중요한가**: [어떤 결론을 지지하는가]
- **어떻게 읽는가**: [축, 범례, 핵심 비교 포인트]

### 표
#### Table X (paper)
- **출처**: Paper Table X (page Y)
- **왜 중요한가**: [어떤 결론을 지지하는가]

옵션 A: 단순한 표라면 Markdown으로 옮긴다.
| Column | Column | Column |
|---|---|---|
| ... | ... | ... |

옵션 B: 복잡한 표라면 이미지로 붙인다.
![Table X](Attachments/[paper-slug]/table-x.png)

## 한계와 해석상 주의점
- [논문이 직접 인정하는 한계]
- [실험하지 않은 것]
- [주장이 일반화되지 않을 수 있는 지점]

## 재현 메모
- **Code**: [repo + commit 또는 release]
- **Config**: [실행 entrypoint나 설정 포인트]
- **Gotchas**: [놓치기 쉬운 구현 디테일]

## 연결점
- **관련 논문 / 노트**: [[...]], [[...]]
- **내 가설**: [mechanism-level guess]
- **다음에 볼 것**: [구체적인 next action]

## Checklist
- [ ] 핵심 metric에 수식과 해석이 들어가 있다
- [ ] 주요 claim이 specific figure/table에 연결되어 있다
- [ ] 재사용 가능한 figure/table anchor가 남아 있다

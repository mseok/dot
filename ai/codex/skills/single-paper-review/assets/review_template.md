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
[2-5문장. 무엇이 문제였는지, 어떤 메커니즘/설계로 풀었는지, headline result가 무엇인지, 무엇을 기억해야 하는지 적는다. 지면이 짧으면 background보다 method novelty를 우선 쓴다.]

## 한 줄 기여
1. [기여 1]
2. [기여 2]
3. [기여 3]

## 문제 설정
- **Task**: [무엇을 예측/생성/최적화하는가?]
- **Inputs/outputs**: [필요하면 notation과 shape까지]
- **Assumptions**: [데이터, 제약, prior]
- **왜 필요한가 / 기존 방식은 어디서 깨지는가**: [failure mode 또는 gap]
- **이 논문의 핵심 method claim**: [기존 방법과 무엇이 구조적으로 다른가?]

## 방법 개요
[5-10줄 정도로 전체 pipeline을 설명한다. 가능하면 stage별로 `input -> module -> output` 흐름이 보이게 쓴다. 필요하면 텍스트 기반 mini diagram을 포함한다.]

## 방법 상세
### 핵심 구성요소
- [Module A: 입력, 출력, 핵심 연산/수식, 왜 필요한지]
- [Module B: prior 대비 무엇이 달라졌는지]
- [Module C: 다른 블록과 어떻게 연결되는지]

### 데이터 흐름 / 입출력
- **Representation**: [token, graph, 3D coordinate, latent 등]
- **Per-stage I/O**: [stage별 tensor/object shape 또는 구조]
- **Information bottleneck / inductive bias**: [어디서 제약을 주는가]

### 학습 / 최적화
- **Objective**: [loss, regularizer]
- **Training signal**: [self-supervised / supervised / RL / contrastive 등]
- **Data**: [dataset, preprocessing]
- **Compute**: [논문에 나오면 GPU/TPU, steps, batch size]
- **Hyperparameters**: [핵심 것만]

### 추론 / 샘플링
- **Inference procedure**: [test-time pipeline, refinement, reranking]
- **Sampling / decoding**: [beam, diffusion step, autoregressive rollout 등]
- **Failure mode**: [어떤 입력에서 취약한지]

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
- [각 claim이 어떤 method component를 지지하는지도 한 줄로 연결한다.]

### Ablation 및 추가 분석
- [무엇을 바꿨는지, 기대 효과가 무엇인지, 실제로 무엇이 일어났는지]

### 정성 분석
- [그림이 무엇을 보여주는지, 무엇을 봐야 하는지]

## 본문 그림 모음
[이 섹션만 보면 main paper body의 Figure 1..N을 순서대로 모두 훑을 수 있어야 한다. note가 하위 폴더에 있으면 attachment 경로를 relative path에 맞게 조정한다. supplementary/appendix figure는 필요할 때만 별도 표기한다.]

### Figure 1
![Figure 1](Attachments/[paper-slug]/fig-1.png)
- **출처**: Paper Figure 1 (page Y)
- **왜 중요한가**: [이 figure가 지지하는 method/result claim]
- **어떻게 읽는가**: [축, 범례, 패널별 핵심 비교 포인트]
- **본문 연결**: [어느 방법/실험 섹션과 직접 연결되는가]

### Figure 2
![Figure 2](Attachments/[paper-slug]/fig-2.png)
- **출처**: Paper Figure 2 (page Y)
- **왜 중요한가**: [이 figure가 지지하는 method/result claim]
- **어떻게 읽는가**: [축, 범례, 패널별 핵심 비교 포인트]
- **본문 연결**: [어느 방법/실험 섹션과 직접 연결되는가]

[Figure 3..N도 같은 형식으로 이어서 넣는다. 본문 Figure가 누락되면 번호와 사유를 적는다.]

## 재사용 가능한 그림 / 표
`본문 그림 모음`은 exhaustive section이다. 여기서는 다른 note에서 특히 다시 인용할 핵심 figure/table만 추려서 anchor를 남긴다.

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
- **Method-sensitive knobs**: [성능에 특히 민감한 objective, schedule, sampler, threshold]

## 연결점
- **관련 논문 / 노트**: [[...]], [[...]]
- **내 가설**: [mechanism-level guess]
- **다음에 볼 것**: [구체적인 next action]

## Checklist
- [ ] TL;DR과 기여가 method novelty를 우선 전달한다
- [ ] 각 핵심 module의 입력/출력/역할이 드러난다
- [ ] objective와 inference 절차가 빠지지 않았다
- [ ] 핵심 metric에 수식과 해석이 들어가 있다
- [ ] 주요 claim이 specific figure/table에 연결되어 있다
- [ ] main paper body의 Figure 1..N이 `Attachments/[paper-slug]/`에 저장되어 note에 모두 embed되어 있다
- [ ] 누락된 body figure가 있으면 번호와 이유가 적혀 있다
- [ ] 재사용 가능한 figure/table anchor가 남아 있다

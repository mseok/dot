# Note Polish Patterns

Use these examples as local rewrite patterns, not rigid templates.

## 1. Make vague criticism specific

Before:

```text
이 구조는 비효율적이다.
```

After:

```text
이 구조는 단일 embedding 을 reuse 하지 못하고 partner-conditioned computation 을 반복해야 해서, pair-level recomputation cost 가 크다.
```

Reason:

- name the axis of failure
- replace a generic adjective with a mechanism

## 2. Turn a claim into claim -> why -> implication

Before:

```text
기존 representation 은 multimer 문제에 적합하지 않다.
```

After:

```text
기존 representation 은 대체로 single-chain objective 를 중심으로 학습되기 때문에, partner-specific compatibility 나 interface-aware signal 을 직접 encode 하도록 강제되지 않는다. 그래서 multimer downstream 에서는 pair relation 이 late stage 에서만 들어오게 된다.
```

Reason:

- state the claim
- explain why it happens
- show why it matters

## 3. Preserve Korean-dominant prose with English technical terms

Before:

```text
This objective is not good for representation learning because it mainly optimizes the final structure quality and the representation becomes only an internal latent for the generator.
```

After:

```text
이 objective 는 representation learning 자체를 직접 최적화한다기보다, 최종 structure quality 를 높이는 방향으로 설계되어 있다. 그 결과 representation 은 reusable feature 라기보다 generator 내부 latent state 에 가까워진다.
```

Reason:

- keep the paragraph readable in Korean
- keep standard technical terms in English where they are more natural

## 4. Polish a meeting note without turning it into an essay

Before:

```text
- 모델 방향 다시 논의함
- baseline 은 유지하되 더 큰 데이터셋도 보기로 함
- 다음주까지 정리
```

After:

```text
## Decision
- baseline 은 유지한다.
- 추가로 더 큰 데이터셋에서 scaling trend 를 확인한다.

## Rationale
- 현재 baseline 을 버릴 만큼의 반례는 아직 없다.
- 다만 dataset scale 에 따른 failure mode 는 아직 확인되지 않았다.

## Next step
- 다음 주 전까지 larger dataset 실험 설계를 정리한다.
```

Reason:

- preserve scanability
- expose the actual decision and follow-up

## 5. Give a rough note a cleaner ending

Before:

```text
아직 잘 모르겠고 좀 더 봐야 할 것 같다.
```

After:

```text
현재 결론은 보류하는 것이 맞다. 다만 다음에 확인할 포인트는 두 가지다: (1) 이 가정이 실제 데이터 분포에서 유지되는가, (2) compute bottleneck 이 trunk 인지 head 인지 분리해서 볼 수 있는가.
```

Reason:

- preserve uncertainty
- replace vague closure with actionable uncertainty

# App Store Connect 출시 문구 & 메타데이터 — Arrow Out: Shape Puzzle

App Store Connect에 바로 복사·붙여넣기할 수 있도록 Apple 글자 수 제한과 ASO(앱 스토어 최적화) 규칙에 맞춰 작성한 **한국어 / 영어(US)** 스토어 문구 패키지입니다.
*(내부 생성 규칙·고정 개수·단계별 출현 주기 등 개발 로직은 노출하지 않고, 추후 도형·패턴 확장에도 그대로 쓸 수 있게 구성했습니다.)*

---

## 0. 공통 기본 설정 (App Information)

| 항목 | 권장 입력값 | 비고 |
| --- | --- | --- |
| **홈 화면 표시 이름 (`CFBundleDisplayName`)** | `Arrow Out` | Xcode 프로젝트에 반영 완료 (11자 이하로 말줄임 없음) |
| **주 카테고리 (Primary Category)** | `게임 > 퍼즐` (`Games > Puzzle`) | 핵심 검색 트래픽 |
| **보조 카테고리 (Secondary Category)** | `게임 > 보드` (`Games > Board`) 또는 `전략` (`Strategy`) | 논리·보드 퍼즐 유저 유입 |
| **연령 등급 (Age Rating)** | `4+` | 폭력/사행성/외부 링크 없음 |
| **개인정보 보호 (App Privacy)** | **데이터 수집 안 함** (`Data Not Collected`) | 현재 모든 진행도는 로컬 `UserDefaults`만 사용 |
| **가격 및 판매 지역** | 무료(Free) / 전 세계 | 추후 인앱 결제·광고 도입 시 변경 |

---

## 1. 한국어 (Korean)

### 앱 이름 (App Name — 최대 30자)
- **글로벌 통일안 (권장 — 23자):**
```text
Arrow Out: Shape Puzzle
```
- **한국어 검색 강화안 (20자):**
```text
Arrow Out: 도형 화살표 퍼즐
```

### 부제 (Subtitle — 최대 30자)
- **글로벌 통일안과 조합 시 (23자):**
```text
다채로운 도형 · 미니멀 화살표 탈출 퍼즐
```
- **한국어 검색 강화안과 조합 시 (22자):**
```text
다채로운 도형 · 미니멀 논리 탈출 퍼즐
```

### 프로모션 텍스트 (Promotional Text — 최대 170자, 현재 96자)
> 심사를 다시 거치지 않고 언제든 수정할 수 있는 상단 강조 문구입니다.
```text
막히지 않은 화살표를 탭해 보드를 비우세요. 비행기·별·나비·로켓 등 다채로운 도형 보드와 최대 100×100 초대형 퍼즐까지, 시간 제한 없이 순수한 논리에만 집중하세요.
```

### 설명 (Description — 최대 4,000자)
```text
얽혀 있는 화살표들의 탈출구를 찾아내는 가장 순수하고 미니멀한 논리 퍼즐.

규칙은 단 하나입니다.
앞이 막혀 있지 않은 화살표를 탭해 보드 밖으로 날려 보내세요. 모든 화살표를 비우면 스테이지가 클리어됩니다.

단순해 보이지만, 겹겹이 얽힌 방향과 순서를 잘못 고르면 하트를 잃게 됩니다. 한 수 앞을 읽고 가장 먼저 풀어야 할 매듭을 찾아내세요.

■ 다채로운 실루엣 도형 보드
비행기, 별, 나비, 로켓, 하트, 고양이 등 수십 가지 독창적인 실루엣으로 구성된 스페셜 보드가 스테이지 곳곳에서 등장합니다. 매번 새로운 도형을 해체하는 시각적 쾌감을 경험하세요.

■ 정교하게 설계된 미로 구조
• 소용돌이, 지그재그, 동심원 등 다채로운 보드 패턴으로 매 판 색다른 전략
• 모든 스테이지가 100% 해답을 보장하는 순수 논리 퍼즐

■ 작게 시작해 최대 100×100 초대형 챌린지까지
가볍게 몸을 푸는 초반 보드부터 최대 100×100 격자까지 확장되는 압도적인 스케일! 120fps의 부드러운 핀치 줌과 드래그 탐색으로 거대한 보드도 손끝으로 쾌적하게 풀어낼 수 있습니다.

■ 오직 퍼즐에만 몰입하는 미니멀 디자인
• 불필요한 테두리와 시각적 소음을 덜어낸 깨끗한 단색 화살표 디자인
• 막힌 화살표를 잘못 탭하면 붉은색으로 표시되어, 탈출 전까지 한눈에 파악
• 막히는 순간에는 다음 탈출 화살표로 부드럽게 이동해 알려주는 스마트 힌트
• 눈이 편안한 라이트 모드 & 다크 모드 완벽 지원
• 타이머 없음 · 오프라인 플레이 · 언제 닫아도 그 자리에서 바로 이어하기

잠깐의 휴식부터 깊은 두뇌 몰입까지, Arrow Out과 함께 머리를 맑게 정리해 보세요.
```

### 키워드 (Keywords — 최대 100자, 현재 96자)
> 쉼표 뒤 띄어쓰기를 넣지 않아야 검색 키워드를 최대한 많이 등록할 수 있습니다. (앱 이름·부제에 이미 들어간 단어는 중복 제외)
```text
두뇌,논리,미로,탭,어웨이,블록,길찾기,뇌운동,집중력,힐링,오프라인,단순한,중독성,무료게임,어려운,보드,전략,실루엣,패턴,정리,심플,퀴즈,IQ,시간때우기,추리,무한,두뇌회전
```

### 새로운 기능 (What's New in This Version — v1.0)
```text
Arrow Out: Shape Puzzle 정식 출시!
• 다채로운 실루엣 도형 보드와 정교한 미로 패턴
• 최대 100×100 초대형 스테이지와 부드러운 120fps 핀치 줌·패닝
• 직관적인 막힘 표시, 스마트 힌트, 라이트/다크 모드 및 자동 이어하기 지원
```

---

## 2. 영어 (English — U.S.)

### App Name (Max 30 chars — 23 chars)
```text
Arrow Out: Shape Puzzle
```

### Subtitle (Max 30 chars — 28 chars)
```text
Minimalist Logic Maze Escape
```

### Promotional Text (Max 170 chars — 165 chars)
```text
Tap unblocked arrows to clear the board. Discover iconic shape boards and massive 100×100 logic grids with smooth pinch zoom, smart hints, and pure minimalist focus.
```

### Description (Max 4,000 chars)
```text
Untangle the paths. Clear every arrow. Experience the purest minimalist logic puzzle.

There is only one rule:
Tap any arrow with a clear path ahead to launch it off the board. Clear every last arrow to complete the stage.

Easy to grasp in seconds, yet deeply satisfying to master. One wrong tap into a blocked path costs a heart—read the interlocking chains, find the key release point, and watch the entire puzzle unravel.

■ ICONIC SILHOUETTE SHAPE BOARDS
Discover a rich collection of handcrafted shape stages—Airplanes, Stars, Butterflies, Rockets, Hearts, Cats, and many more. Every special board brings a fresh silhouette to unravel.

■ DEEPLY INTERLOCKING MAZE LAYOUTS
• Master Spiral Vortexes, Serpentine Mazes, Concentric Fortresses, and intricate knotted paths
• Every single stage is guaranteed 100% solvable with zero deadlocks

■ SCALE UP TO MASSIVE 100×100 GRIDS
Start relaxed and climb into monumental logic challenges—reaching up to 100×100 grids at higher stages. Glide across dense boards effortlessly with silky-smooth 120fps pinch-to-zoom and panning.

■ DESIGNED FOR PURE FOCUS
• Ultra-clean monochrome aesthetic with zero clutter or distracting borders
• Clear crimson feedback marks blocked arrows until you free them
• Smart Hints smoothly glide directly to your next valid move whenever you need a nudge
• Full Light Mode and Dark Mode themes
• No countdown timers, offline playable, and automatic mid-level resume

Whether you have two minutes or an hour to unwind, Arrow Out delivers crisp, tactile brain training at your own pace.
```

### Keywords (Max 100 chars — 96 chars)
> No spaces after commas; excludes words already indexed from Name & Subtitle (`arrow`, `out`, `shape`, `puzzle`, `minimalist`, `logic`, `maze`, `escape`).
```text
tap,away,brain,teaser,untangle,path,grid,zen,offline,casual,mind,game,blocks,direction,labyrinth
```

### What's New in This Version (v1.0)
```text
Welcome to Arrow Out: Shape Puzzle!
• Handcrafted silhouette shape boards and interlocking maze layouts
• Scale up to massive 100×100 grids with silky 120fps pinch zoom & pan
• Instant crimson blocked feedback, smart hints, Light/Dark themes, and auto-resume
```

---

## 3. 스크린샷 구성 가이드 (App Store 6.9" iPhone — `1320 × 2868` px)

Apple App Store Connect의 **iPhone 6.9" Display** 슬롯에 업로드하면 6.7"/6.5"/6.1" 화면에 자동 스케일링됩니다.

| 순서 | 파일명 (KO / EN) | 핵심 메시지 | 화면 연출 |
| --- | --- | --- | --- |
| **1** | `01-Hero-Airplane-{KO,EN}.png` | 화살표를 풀어 모양을 완성하세요 / Tap. Slide. Unravel Every Shape. | 비행기 실루엣 보드 (핵심 플레이 훅) |
| **2** | `02-Smart-Hint-{KO,EN}.png` | 막히는 순간엔 스마트 힌트로 돌파 / Instant Clarity. Smart Hints Anytime. | 별(Star) 실루엣 + 빨간 막힘 표시 & 골드 스마트 힌트 |
| **3** | `03-Spiral-Strategy-{KO,EN}.png` | 깊이 꼬인 소용돌이 미로 퍼즐 / Deep Interlocking Spiral Mazes | 소용돌이(Spiral Vortex) 보드 + 전략적 논리 챌린지 |
| **4** | `04-Mega-Challenge-{KO,EN}.png` | 최대 100×100 초대형 챌린지 보드 / Up to 100×100 Mega Shape Boards | 고밀도 나비(Butterfly) 보드 + 120fps 핀치 줌 강조 |
| **5** | `05-DarkMode-Zen-{KO,EN}.png` | 눈이 편안한 다크 모드 · 언제든 이어서 플레이 / Crisp Dark Mode · Play at Your Pace | 다크 모드 로켓(Rocket) 보드 + 오프라인/자동저장 |

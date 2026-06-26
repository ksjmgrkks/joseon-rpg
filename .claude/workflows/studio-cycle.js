export const meta = {
  name: 'studio-cycle',
  description: '1인 게임 스튜디오 한 사이클 — 기획→내러티브→병렬제작→통합→QA게이트→커밋',
  whenToUse: '게임에 한 조각(수직 슬라이스)을 추가/개선할 때. args로 목표 문자열을 넘기면 그 목표로, 없으면 HANDOFF의 다음 할 일을 진행.',
  phases: [
    { title: 'Plan', detail: '프로듀서: 목표를 수직 슬라이스로 좁히고 역할별 작업 배분', model: 'opus' },
    { title: 'Narrative', detail: '내러티브: 이번 슬라이스의 감정/미스터리 비트 + 컷신 대본', model: 'opus' },
    { title: 'Build', detail: '디자이너·아티스트·사운드 병렬 제작 (영역 비중첩)' },
    { title: 'Integrate', detail: '프로그래머: GDScript 통합 + 헤드리스 자체검증', model: 'opus' },
    { title: 'QA', detail: 'QA: 테스트+스크린샷 적대적 게이트 (그린까지 최대 2회 수정 루프)', model: 'opus' },
    { title: 'Ship', detail: '프로듀서: HANDOFF 갱신 + 커밋 (푸시는 사용자 승인)', model: 'opus' },
  ],
}

// ── 목표 해석: args 가 {goal} 객체이거나 문자열, 둘 다 없으면 HANDOFF 다음 할 일 ──
const GOAL =
  (args && typeof args === 'object' && args.goal) ? args.goal :
  (typeof args === 'string' && args.trim()) ? args :
  'HANDOFF의 바로 다음 할 일(전투 게임성 polish) 중 검증 가능한 한 조각을 골라 진행하라'

// ── 단계 간 구조적 인수인계 스키마 ──
const PLAN_SCHEMA = {
  type: 'object',
  required: ['slice', 'emotional_beat', 'tasks'],
  properties: {
    slice: { type: 'string', description: '이번 사이클에 만들 한 조각(수직 슬라이스)' },
    emotional_beat: { type: 'string', description: '이번 슬라이스가 주려는 감정/미스터리 한 줄' },
    tasks: {
      type: 'object',
      properties: {
        narrative: { type: 'string' },
        designer: { type: 'string' },
        artist: { type: 'string' },
        sound: { type: 'string' },
        engineer: { type: 'string' },
      },
    },
    needs_art: { type: 'boolean', description: '이번 슬라이스에 새 아트가 필요한가' },
    needs_sound: { type: 'boolean', description: '이번 슬라이스에 새 사운드가 필요한가' },
  },
}

const NARRATIVE_SCHEMA = {
  type: 'object',
  required: ['summary'],
  properties: {
    summary: { type: 'string', description: '이번 슬라이스의 서사 한 줄' },
    cutscenes: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          where: { type: 'string', description: '어느 스테이지 진입/클리어/보스 등장' },
          lines: { type: 'array', items: { type: 'string' } },
        },
      },
    },
    env_story: { type: 'string', description: '아티스트에게 넘길 환경 서사 메모' },
  },
}

const BUILD_SCHEMA = {
  type: 'object',
  required: ['done', 'summary'],
  properties: {
    done: { type: 'boolean' },
    summary: { type: 'string' },
    files: { type: 'array', items: { type: 'string' } },
    handoff_to_engineer: { type: 'string', description: '프로그래머가 통합 시 알아야 할 것(키 구조/배선/없으면 -)' },
  },
}

const ENGINEER_SCHEMA = {
  type: 'object',
  required: ['summary', 'tests_run'],
  properties: {
    summary: { type: 'string' },
    files: { type: 'array', items: { type: 'string' } },
    tests_run: { type: 'string', description: '돌린 헤드리스 테스트와 결과' },
    self_check_green: { type: 'boolean' },
  },
}

const QA_SCHEMA = {
  type: 'object',
  required: ['green'],
  properties: {
    green: { type: 'boolean' },
    failures: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          what: { type: 'string' },
          repro: { type: 'string' },
          suspect: { type: 'string', description: '의심 파일/함수' },
        },
      },
    },
    deferred: { type: 'array', items: { type: 'string' }, description: '사용자 실플레이 확인 필요(보류, 불합격 아님)' },
    screenshots: { type: 'array', items: { type: 'string' } },
  },
}

const SHIP_SCHEMA = {
  type: 'object',
  required: ['committed', 'report'],
  properties: {
    committed: { type: 'boolean' },
    commit_subject: { type: 'string' },
    report: { type: 'string', description: '한 일 / 검증 / 내가 정한 것 / 남은 것' },
    push_pending: { type: 'boolean', description: '푸시 대기 여부(이 워크플로는 푸시하지 않음)' },
  },
}

// ── 1) 기획 ──────────────────────────────────────────────
phase('Plan')
const plan = await agent(
  `목표: "${GOAL}"

HANDOFF.md 와 CLAUDE.md 를 읽고, 이 목표를 한 번에 검증 가능한 수직 슬라이스 하나로 좁혀라. 각 역할(내러티브/디자이너/아티스트/사운드/프로그래머)에게 맡길 구체 작업을 정하라. 이번 슬라이스에 새 아트/사운드가 불필요하면 needs_art/needs_sound 를 false 로.`,
  { agentType: 'producer', schema: PLAN_SCHEMA, phase: 'Plan', label: 'producer:plan' }
)
if (!plan) return { error: '기획 단계 실패 — 사이클 중단' }
log(`슬라이스: ${plan.slice}`)

// ── 2) 내러티브 (기획 바로 다음, 제작의 뼈대) ──────────────
phase('Narrative')
const story = await agent(
  `이번 수직 슬라이스: "${plan.slice}"
감정/미스터리 비트: "${plan.emotional_beat}"
네 작업: ${(plan.tasks && plan.tasks.narrative) || '이 슬라이스의 컷신/보스연출/환경서사를 설계하라'}

산나비식으로 짧고 강하게. 전투를 끊지 않는 컷신 레이어로만(스테이지 진입/클리어, 보스 등장 연출). 사극체. 옛 RPG 대화트리 부활 금지.`,
  { agentType: 'narrative', schema: NARRATIVE_SCHEMA, phase: 'Narrative', label: 'narrative' }
)
const storyCtx = story
  ? `[내러티브] ${story.summary}\n환경서사: ${story.env_story || '-'}`
  : '[내러티브 산출 없음]'

// ── 3) 병렬 제작 (영역 비중첩 → 충돌 없음) ─────────────────
phase('Build')
const builders = [
  () => agent(
    `슬라이스: "${plan.slice}"\n${storyCtx}\n네 작업: ${(plan.tasks && plan.tasks.designer) || '전투 수치/페이싱을 이 슬라이스에 맞게 조정하라'}\n\nassets/data·assets/stages 의 json 과 기획 문서만 건드려라. scripts 가 노출해야 할 건 스펙으로 넘겨라.`,
    { agentType: 'designer', schema: BUILD_SCHEMA, phase: 'Build', label: 'designer' }
  ),
]
if (plan.needs_art !== false) {
  builders.push(() => agent(
    `슬라이스: "${plan.slice}"\n${storyCtx}\n네 작업: ${(plan.tasks && plan.tasks.artist) || '필요한 스프라이트/배경/소품을 만들어라'}\n\n팔레트 25색·조선풍 고유성 준수. PixelLab 크레딧은 아껴 쓰고(HANDOFF의 잔여 확인), 스크린샷으로 확인하라. 불필요하면 변경 없음으로 보고.`,
    { agentType: 'artist', schema: BUILD_SCHEMA, phase: 'Build', label: 'artist' }
  ))
}
if (plan.needs_sound !== false) {
  builders.push(() => agent(
    `슬라이스: "${plan.slice}"\n${storyCtx}\n네 작업: ${(plan.tasks && plan.tasks.sound) || '필요한 BGM/SFX 를 만들거나 조정하라'}\n\ntools/audio 신디사이저로. 불필요하면 변경 없음으로 보고.`,
    { agentType: 'sound', schema: BUILD_SCHEMA, phase: 'Build', label: 'sound' }
  ))
}
const built = (await parallel(builders)).filter(Boolean)
const buildCtx = built.length
  ? built.map(b => `- ${b.summary} (파일: ${(b.files || []).join(', ') || '-'})\n  통합지시: ${b.handoff_to_engineer || '-'}`).join('\n')
  : '(제작 산출물 없음)'

// ── 4) 통합 (프로그래머) ──────────────────────────────────
phase('Integrate')
let eng = await agent(
  `슬라이스: "${plan.slice}"\n${storyCtx}\n네 작업: ${(plan.tasks && plan.tasks.engineer) || '위 산출물을 엔진에 통합하라'}\n\n전문가 산출물:\n${buildCtx}\n\nGDScript 전용. 컷신은 전투를 끊지 않는 레이어로 구현하고 GAMEPLAY_ONLY 토글을 존중. 변경 후 헤드리스 테스트를 직접 돌려 결과를 보고하라.`,
  { agentType: 'engineer', schema: ENGINEER_SCHEMA, phase: 'Integrate', label: 'engineer' }
)

// ── 5) QA 게이트 (그린까지 최대 2회 수정 루프) ─────────────
phase('QA')
let qa = null
let round = 0
const MAX_FIX = 2
while (true) {
  qa = await agent(
    `이번 슬라이스: "${plan.slice}"\n프로그래머 보고: ${eng ? eng.summary : '없음'} / 돌린 테스트: ${eng ? eng.tests_run : '-'}\n\n헤드리스 테스트 전체 실행 + 이번 변경이 닿는 화면 스크린샷 + 적대적 탐색으로 게이트를 판정하라. 그린이 아니면 구체적 실패 목록(무엇/재현/의심파일)을 내라. 손맛·밸런스처럼 스크린샷으로 못 잡는 건 deferred 로.`,
    { agentType: 'qa', schema: QA_SCHEMA, phase: 'QA', label: `qa:round${round + 1}` }
  )
  if (!qa || qa.green) break
  if (round >= MAX_FIX) { log(`QA 불합격 — 수정 ${MAX_FIX}회 소진, 사람 개입 필요`); break }
  round++
  const failures = qa.failures || []
  log(`QA 불합격 (${failures.length}건) — 프로그래머 수정 라운드 ${round}`)
  const fixList = failures.map(f => `- ${f.what} | 재현: ${f.repro} | 의심: ${f.suspect}`).join('\n')
  eng = await agent(
    `QA가 다음 결함을 보고했다. 고쳐라:\n${fixList}\n\n원래 슬라이스: "${plan.slice}". 고친 뒤 헤드리스 테스트를 다시 돌려 결과를 보고하라.`,
    { agentType: 'engineer', schema: ENGINEER_SCHEMA, phase: 'QA', label: `engineer:fix${round}` }
  )
}

// ── 6) 마감 (프로듀서: HANDOFF 갱신 + 커밋, 푸시는 안 함) ───
phase('Ship')
const green = !!(qa && qa.green)
const ship = await agent(
  `이번 사이클을 마감하라.\n슬라이스: "${plan.slice}"\nQA 결과: ${green ? '그린' : '미통과/보류'}${qa ? '\n' + JSON.stringify({ failures: qa.failures || [], deferred: qa.deferred || [] }) : ''}\n\nHANDOFF.md 의 '현재 상태 / 바로 다음 할 일 / 완료 로그' 를 갱신하고 의미 단위로 커밋하라. 푸시는 하지 말고 push_pending=true 로 남겨라. 그린이 아니면 남은 결함을 '바로 다음 할 일'에 적어라.`,
  { agentType: 'producer', schema: SHIP_SCHEMA, phase: 'Ship', label: 'producer:ship' }
)

return {
  goal: GOAL,
  slice: plan.slice,
  green,
  qa_failures: qa ? (qa.failures || []) : [],
  deferred: qa ? (qa.deferred || []) : [],
  committed: ship ? !!ship.committed : false,
  push_pending: ship ? (ship.push_pending !== false) : true,
  report: ship ? ship.report : '마감 보고 없음',
}

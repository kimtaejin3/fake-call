import '../models/caller.dart';
import '../models/scenario.dart';

const List<Caller> kCallers = [
  Caller(
    id: 'mom',
    name: '엄마',
    voiceId: 'voice_female_01',
    persona: 'concerned_parent',
    emoji: '👩',
  ),
  Caller(
    id: 'dad',
    name: '아빠',
    voiceId: 'voice_male_01',
    persona: 'concerned_parent',
    emoji: '👨',
  ),
  Caller(
    id: 'friend',
    name: '친구',
    voiceId: 'voice_female_02',
    persona: 'close_friend',
    emoji: '🧑',
  ),
  Caller(
    id: 'boss',
    name: '직장 상사',
    voiceId: 'voice_male_02',
    persona: 'strict_boss',
    emoji: '👔',
  ),
  Caller(
    id: 'partner',
    name: '연인',
    voiceId: 'voice_female_03',
    persona: 'loving_partner',
    emoji: '💛',
  ),
];

const List<Scenario> kScenarios = [
  Scenario(
    id: 'come_home',
    title: '빨리 집에 들어오라고 해줘',
    prompt: 'ROLE: 너는 사용자의 가족이다. '
        'GOAL: 사용자가 현재 있는 자리에서 자연스럽게 빠져나갈 수 있도록 집으로 빨리 들어오라고 말한다. '
        'RULES: 한국어로 대화한다. 실제 전화처럼 짧게 말한다. 답변은 한 번에 1~2문장만 한다. '
        '통화는 약 20~40초 정도로 진행한다. 마지막에는 자연스럽게 통화를 종료한다.',
    firstMessage: '여보세요? 너 지금 어디야?',
  ),
  Scenario(
    id: 'urgent',
    title: '급한 일이 있다고 해줘',
    prompt: 'ROLE: 너는 사용자의 지인이다. '
        'GOAL: 급한 일이 생겨서 사용자가 지금 바로 와야 한다고 말한다. '
        'RULES: 한국어로 짧게, 1~2문장씩, 20~40초 내 자연스럽게 종료.',
    firstMessage: '여보세요? 야, 지금 통화 돼?',
  ),
  Scenario(
    id: 'work_problem',
    title: '회사에 문제가 생겼다고 해줘',
    prompt: 'ROLE: 너는 사용자의 회사 동료 또는 상사다. '
        'GOAL: 회사에 문제가 생겨 사용자가 지금 확인해야 한다고 말한다. '
        'RULES: 한국어로 짧게, 1~2문장씩, 20~40초 내 자연스럽게 종료.',
    firstMessage: '여보세요, 지금 통화 가능하세요? 급한 일이 좀 생겨서요.',
  ),
  Scenario(
    id: 'casual',
    title: '자연스럽게 통화해줘',
    prompt: 'ROLE: 너는 사용자와 가까운 사람이다. '
        'GOAL: 일상적인 안부 통화를 한다. '
        'RULES: 한국어로 짧게, 1~2문장씩, 20~40초 내 자연스럽게 종료.',
    firstMessage: '여보세요? 뭐 해?',
  ),
];

class DelayOption {
  final String label;
  final int seconds;
  const DelayOption(this.label, this.seconds);
}

const List<DelayOption> kDelayOptions = [
  DelayOption('지금', 0),
  DelayOption('10초 후', 10),
  DelayOption('30초 후', 30),
  DelayOption('1분 후', 60),
  DelayOption('3분 후', 180),
];

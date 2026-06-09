# GitHub Actions 워크플로 — 사용자 설치 안내

원래는 `.github/workflows/` 아래 두려고 했으나, Claude Code 가 쓰는 git credential
(OAuth 앱)에 `workflow` 스코프가 없어 GitHub 가 push 를 거부했습니다.
**워크플로 파일은 사용자가 직접 레포에 추가해야 합니다.** 두 가지 방법:

## 방법 A — PC 에서 한 줄로

```bash
cd ~/projects/joseon-rpg
mkdir -p .github/workflows
cp docs/ci/web-build.yml      .github/workflows/web-build.yml
cp docs/ci/headless-tests.yml .github/workflows/headless-tests.yml
git add .github/workflows
git commit -m "ci: add GitHub Actions workflows (web export + headless tests)"
git push
```

PC 의 `git` credential 이 `workflow` 스코프가 있는 PAT 이거나 SSH 키이면 즉시 동작합니다.
(gh CLI 쓰시면 `gh auth refresh -s workflow` 한 번 실행 후 위 push.)

## 방법 B — GitHub 웹에서 직접 만들기

레포 → **Add file → Create new file** → 파일명에 `.github/workflows/web-build.yml`
입력 → `docs/ci/web-build.yml` 내용 그대로 붙여넣기 → commit. headless 도 동일.

## 동작 요약

- `web-build.yml`: main 푸시 / 수동 실행 시 Godot 4.3 Web export → `build/web/` 아티팩트.
  GitHub Pages 배포는 워크플로 하단 두 단계가 주석 처리돼 있어 Settings → Pages 에서
  Source 를 'GitHub Actions' 로 바꾸고 주석을 풀면 활성화됩니다. (private 레포는 Pro 필요.)
- `headless-tests.yml`: main 푸시 / PR 마다 `tests/*.tscn` 전체를 godot --headless 로
  실행하고 실패 시 워크플로 실패. 회귀 방지용.

## 향후

만약 Cloudflare Pages 로 호스팅하실 거면, Cloudflare 가 직접 GitHub 레포를 빌드하는
방식(빌드 명령: `godot --headless --export-release "Web" build/web/index.html`,
빌드 출력: `build/web`)이 가장 단순합니다. CF 계정 연결만 사용자가 직접 해 주시면 됩니다.

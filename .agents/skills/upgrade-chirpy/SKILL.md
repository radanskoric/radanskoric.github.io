---
name: upgrade-chirpy
description: Upgrade this site's Chirpy theme gem to a requested version, preserving significant template customizations and verifying visual and functional parity.
disable-model-invocation: true
---

# Upgrade Chirpy

Given a target version, complete the upgrade and validation. Preserve significant appearance, content, URLs, and integrations; minor upstream visual changes are acceptable. For a plan-only request, deliver analysis without implementing.

## 1. Capture the current behavior

- Read the project guide, Ruby version, dependency/configuration files, deployment workflow, and worktree status. Preserve existing user changes.
- Run `bundle info jekyll-theme-chirpy` to find the actual installed version and originals; do not infer it from the Gemfile constraint. Resolve and state the concrete target release.
- Before updating, compare **every local override against its original in the installed gem**, including layouts, includes, data, CSS, feeds, and assets. Trace custom-only files through their callers. Save diffs and an inventory of meaningful additions, removals, styling, and integrations; ignore formatting and duplication. Investigate unclear behavioral differences before discarding them.
- Check whether the reference server is running on port 4500 and matches the current site. If it is not running, ask whether the user authorizes you to start it in a separate worktree or will start it themselves; wait for their answer before creating the worktree or starting the reference server. Include relevant uncommitted source and Git history for last-modified dates in an authorized baseline. Keep it unchanged. Default to upgrade port 4000; avoid disrupting occupied ports. Capture baseline HTML/screenshots.

## 2. Research and upgrade

Read official release notes and theme/starter comparisons from the installed release through the target, including intermediate migrations. Check the published gem's actual assets, not only its source tag.

Inspect configuration/front-matter/include renames, analytics/comments/media/SEO wiring, CSS bundling, JavaScript dependencies, Ruby/Jekyll compatibility, and deployment changes.

- Update the requirement to the resolved target; normally run `bundle update jekyll-theme-chirpy --conservative`. Review the lockfile and limit unrelated dependency changes.
- **Recreate overrides from the newly installed gem's templates, then reapply significant customizations.** Prefer supported hooks to whole-template copies; remove overrides the new release makes redundant. Preserve upstream fixes and fallbacks.
- **Preserve only the owner's branding, not Chirpy's old branding.** Retain the site's custom identity, logos, favicons, and branded metadata. Any Chirpy branding still used by the site must come from the new gem version; never copy old theme mascots, icons, manifests, or branding metadata merely to preserve parity. Do not reintroduce Chirpy branding where it was intentionally replaced or removed.
- Migrate configuration selectively, preserving permalinks, identity, integration IDs/URLs/parameters, pagination, exclusions, and disabled features. Distinguish required migrations, adopted upstream fixes, and optional features.
- Adapt CSS imports to the target. Check production bundles for classes used by local templates/posts; restore missing styles with small custom rules.
- Check actual gitlinks and self-hosting settings before changing `assets/lib`: a leftover `.gitmodules` entry alone does not establish an active submodule.

Previously customized areas include notices/newsletters; hidden card dates and post hero images; sidebar book/webring links; Plausible and content-bottom tracking; language metadata and Stimulus imports; branded icons and feed logo; image/reference-box/footer styling. Rediscover them from current source, preserving current values rather than reinstating removed features or historical IDs.

## 3. Verify parity

Run the upgraded server in this folder, normally `bundle exec jekyll serve --host 127.0.0.1 --port 4000`.

Compare representative routes: home and pagination; posts covering images, code/TOC, guest authors, diagrams, custom styles, and interactive examples; navigation tabs and taxonomy/archive pages.

- Inspect matching screenshots at desktop/mobile widths in light/dark modes, including sidebar, newsletter placement, image visibility, spacing, and overflow.
- Compare HTML semantically: content, ordering, URLs, metadata, authors, and integration markup. Normalize server origins, timestamps, and whitespace; production compression can remove spacing between block tags without changing appearance.
- Run production build and HTML checks from `AGENTS.md`, and **serve and visually inspect production output too**, using a separate destination/server if needed. Development CDN CSS can conceal missing production styles. Generic static servers may need generated `.html` paths for extensionless post URLs.
- Exercise search, mobile navigation, theme switching, image popups, copying, TOC, diagrams, and live examples. Check new browser errors/failed local assets, comments configuration, SEO/media URLs, and production-only analytics appearing once. Run relevant Ruby-example specs if examples changed.
- **Feed continuity means avoiding false new-article alerts, not freezing the feed representation.** Compare reference and upgraded production feeds for stable feed/entry IDs or GUIDs, canonical links, and per-entry published/updated timestamps; never normalize away changes to these fields. The feed-level build timestamp may change normally. Accept upstream summary/content, formatting, serialization, and bug-fix changes when they do not alter article identity or timestamps; byte-for-byte entry equality is not required. Do not add or retain a feed template or legacy summary include merely to preserve the old output. Investigate differences with a concrete risk of duplicate or false alerts, and use the smallest customization needed for site branding. Reader-specific notification behavior cannot be guaranteed.
- Test analytics with local spies and blocked endpoints; do not submit forms or real events. Use fresh pages for one-shot events, wait for smooth scrolling/initialization, and dispatch realistic input events. Diagnose test timing or tool failures before changing working code. Use another available browser interface if screenshot tooling fails; report unavailable checks.

## 4. Handoff

Require successful checks and significant visual/functional parity; distinguish baseline failures and harmless upstream warnings from regressions. Save the customization inventory, old/new diffs, HTML/screenshots, and results outside generated site output.

Summarize migrations, preserved edits, removed overrides, and intentional differences/limitations. Leave the requested upgraded development server running and report its URL; stop temporary validation resources you created. Commit, push, or deploy only when requested.

# Verge-Navbot-2.0

---

> **Credits to: https://github.com/lnx00/Lmaobox-Navbot for original work**

Navbot from lnx00 revamped and ported over to Verge. Major fixes and optimizations made. Probably won't work for LMAOBox since _some_ of the API schema isn't 1:1 identical, but it'd be quick to get working.

## What Navbot 2.0 Is
- Automatic pathing for objectives. Works for CTF, PL, and CP maps(given you have the navmesh generated)
- Utilizes TF2's native CNavArea::GetClosestPointOnArea and CNavArea::ComputeClosestPointInPortal functions to find best possible movement path
- Mimics NextBot's native NextBotPlayer::PhysicsSimulate, which synthesizes a real CUserCMD to give authentic movement, and uses NextBotGroundLocomotion::ResolveCollision for projecting hit planes iteratively so that corners, walls, and ledges are an impossible issue(major issue in the original Navbot).

## Demonstration Video
[![Demonstration](https://img.youtube.com/vi/tb07YfQSsnI/hqdefault.jpg)](https://www.youtube.com/watch?v=tb07YfQSsnI)

---

## How To Use
> **Note: LNXlib, Navbot, and ImMenu are automatically shipped with Verge upon injection, but the open source is here if you need it or want to make requests/bug reports**
1. Download the latest release: https://github.com/s7nthesise/Verge-Navbot-2.0/releases/tag/1.0
2. Drop lua folder into "C:\Program Files (x86)\Steam\steamapps\common\Team Fortress 2\Verge\"
3. **[Optional]** Drag AutoExecNavbot.lua into "C:\Program Files (x86)\Steam\steamapps\common\Team Fortress 2\Verge\lua\autoexec" **if** you want Navbot to auto execute when injecting Verge
4. Start TF2
5. Open Verge menu(INSERT) -> Lua -> navigate to "Navbot\init.lua" -> click load icon(or right click script -> Load)
6. Join any map and it will handle the rest
7. Press HOME to open/close the Navbot's dedicated menu

**[RECOMMENDED]** Download the navmeshes included from this repo and drop ALL .nav files into "C:\Program Files (x86)\Steam\steamapps\common\Team Fortress 2\tf\maps\".

---

## License
MIT License - do whatever you want with it

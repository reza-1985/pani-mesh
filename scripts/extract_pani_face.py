from collections import deque
from PIL import Image, ImageFilter

src = "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
img = Image.open(src).convert("RGBA")
w, h = img.size
crop = img.crop((int(w * 0.20), int(h * 0.20), int(w * 0.80), int(h * 0.82)))
cw, ch = crop.size
px = crop.load()

bg = [[False] * cw for _ in range(ch)]
q = deque()

def is_bg(r, g, b):
    if r > 165 and g > 145 and b > 110 and abs(r - g) < 55:
        return False
    if r < 95 and g < 105 and b < 150:
        return True
    if b > r + 20 or b > g + 20:
        return True
    if r > 120 and g < 115 and b < 115:
        return True
    return False

for x in range(cw):
    for y in (0, ch - 1):
        if is_bg(*px[x, y][:3]):
            bg[y][x] = True
            q.append((x, y))
for y in range(ch):
    for x in (0, cw - 1):
        if not bg[y][x] and is_bg(*px[x, y][:3]):
            bg[y][x] = True
            q.append((x, y))

while q:
    x, y = q.popleft()
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        nx, ny = x + dx, y + dy
        if 0 <= nx < cw and 0 <= ny < ch and not bg[ny][nx] and is_bg(*px[nx, ny][:3]):
            bg[ny][nx] = True
            q.append((nx, ny))

vis = [[False] * cw for _ in range(ch)]
best = []
for y in range(ch):
    for x in range(cw):
        if not bg[y][x] and not vis[y][x]:
            comp = []
            dq = deque([(x, y)])
            vis[y][x] = True
            while dq:
                cx, cy = dq.popleft()
                comp.append((cx, cy))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < cw and 0 <= ny < ch and not bg[ny][nx] and not vis[ny][nx]:
                        vis[ny][nx] = True
                        dq.append((nx, ny))
            if len(comp) > len(best):
                best = comp

mask = Image.new("L", (cw, ch), 0)
mpx = mask.load()
for x, y in best:
    mpx[x, y] = 255
mask = mask.filter(ImageFilter.GaussianBlur(radius=0.8))
crop.putalpha(mask)

out = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
r_img = crop.resize((220, int(220 * ch / cw)), Image.Resampling.LANCZOS)
out.paste(r_img, ((256 - r_img.width) // 2, (256 - r_img.height) // 2), r_img)
out.save("assets/icons/pani_face_only.png", "PNG")

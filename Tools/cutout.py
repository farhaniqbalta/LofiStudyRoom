"""Cut a character out of an AI edit of a room crop, and rasterise hand-traced polygons."""

def figure(before, after, envelope, threshold=8):
    """Pixels of `after` that belong to the figure: everything inside the hand-drawn envelope except the
    unchanged background that leaks in from the envelope's edge."""
    def same(p):
        x, y = p
        return max(abs(after[y][x][i] - before[y][x][i]) for i in range(3)) <= threshold
    edge = [p for p in envelope if any(q not in envelope for q in ((p[0] + 1, p[1]), (p[0] - 1, p[1]), (p[0], p[1] + 1), (p[0], p[1] - 1)))]
    background, stack = set(), [p for p in edge if same(p)]
    while stack:
        p = stack.pop()
        if p in envelope and p not in background and same(p):
            background.add(p)
            stack += [(p[0] + 1, p[1]), (p[0] - 1, p[1]), (p[0], p[1] + 1), (p[0], p[1] - 1)]
    return envelope - background

def polygon(points):
    """Set of pixels inside a polygon (even-odd rule, pixel centres)."""
    ys = [p[1] for p in points]
    inside = set()
    for y in range(min(ys), max(ys) + 1):
        xs = sorted(x1 + (y + 0.5 - y1) * (x2 - x1) / (y2 - y1)
                    for (x1, y1), (x2, y2) in zip(points, points[1:] + points[:1])
                    if (y1 <= y + 0.5) != (y2 <= y + 0.5))
        for a, b in zip(xs[::2], xs[1::2]):
            inside.update((x, y) for x in range(round(a), round(b)))
    return inside

import { GatewayError } from "./common.mjs";

function stripYamlScalar(value) {
  const trimmed = value.trim();
  if (
    trimmed.length >= 2 &&
    ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
      (trimmed.startsWith("'") && trimmed.endsWith("'")))
  ) {
    return trimmed.slice(1, -1).trim();
  }
  return trimmed;
}

function splitInlineYamlList(value) {
  const trimmed = value.trim();
  if (!trimmed.startsWith("[") || !trimmed.endsWith("]")) return null;
  return trimmed
    .slice(1, -1)
    .split(",")
    .map(stripYamlScalar)
    .filter(Boolean);
}

export function normalizeTag(value) {
  return value.normalize("NFC").trim().replace(/^#+/, "");
}

export function extractFrontmatter(content) {
  const match = content.match(/^---\r?\n([\s\S]*?)\r?\n(?:---|\.\.\.)(?:\r?\n|$)/);
  if (!match) return { has_frontmatter: false, raw: "", body_start: 0 };
  return {
    has_frontmatter: true,
    raw: match[1],
    body_start: match[0].length
  };
}

function frontmatterTags(raw) {
  const lines = raw.split(/\r?\n/);
  const tags = [];
  for (let index = 0; index < lines.length; index += 1) {
    const match = lines[index].match(/^tags\s*:\s*(.*)$/i);
    if (!match) continue;
    const inline = splitInlineYamlList(match[1]);
    if (inline) tags.push(...inline);
    else if (match[1].trim()) tags.push(stripYamlScalar(match[1]));
    else {
      for (let child = index + 1; child < lines.length; child += 1) {
        const item = lines[child].match(/^\s+-\s+(.+?)\s*$/);
        if (item) {
          tags.push(stripYamlScalar(item[1]));
          continue;
        }
        if (/^\s*$/.test(lines[child])) continue;
        break;
      }
    }
    break;
  }
  return tags.map(normalizeTag).filter(Boolean);
}

function withoutCode(content) {
  const lines = content.split(/\r?\n/);
  let fence = null;
  return lines
    .map((line) => {
      const fenceMatch = line.match(/^\s*(`{3,}|~{3,})/);
      if (fenceMatch) {
        const marker = fenceMatch[1];
        if (!fence) fence = { character: marker[0], length: marker.length };
        else if (marker[0] === fence.character && marker.length >= fence.length) fence = null;
        return "";
      }
      if (fence) return "";
      return line.replace(/`[^`]*`/g, "");
    })
    .join("\n");
}

export function extractTags(content) {
  const frontmatter = extractFrontmatter(content);
  const tags = new Set(frontmatterTags(frontmatter.raw));
  const body = withoutCode(content.slice(frontmatter.body_start));
  const pattern = /(?:^|[\s(\[{])#([\p{L}\p{N}_/-]+)/gu;
  for (const match of body.matchAll(pattern)) {
    const tag = normalizeTag(match[1]);
    if (tag) tags.add(tag);
  }
  return [...tags].sort((left, right) => left.localeCompare(right));
}

function normalizedHeadingTitle(value) {
  return value
    .normalize("NFC")
    .replace(/^\s*#{1,6}\s*/, "")
    .replace(/\s+#+\s*$/, "")
    .replace(/\s+/g, " ")
    .trim();
}

export function parseHeadings(content) {
  const lines = content.split(/(?<=\n)/);
  const headings = [];
  const stack = [];
  let fence = null;
  for (let index = 0; index < lines.length; index += 1) {
    const withoutNewline = lines[index].replace(/\r?\n$/, "");
    const fenceMatch = withoutNewline.match(/^\s*(`{3,}|~{3,})/);
    if (fenceMatch) {
      const marker = fenceMatch[1];
      if (!fence) fence = { character: marker[0], length: marker.length };
      else if (marker[0] === fence.character && marker.length >= fence.length) fence = null;
      continue;
    }
    if (fence) continue;
    const match = withoutNewline.match(/^(#{1,6})[ \t]+(.+?)[ \t]*#*[ \t]*$/);
    if (!match) continue;
    const level = match[1].length;
    const title = normalizedHeadingTitle(match[2]);
    if (!title) continue;
    stack.length = level - 1;
    stack[level - 1] = title;
    const headingPath = stack.filter(Boolean);
    headings.push({
      level,
      title,
      heading_path: headingPath.join("::"),
      line: index
    });
  }
  return { lines, headings };
}

function availableHeadingDetails(headings) {
  return headings.slice(0, 200).map(({ level, title, heading_path, line }) => ({
    level,
    title,
    heading_path,
    line
  }));
}

export function resolveHeading(content, requestedPath) {
  const requested = requestedPath
    .split("::")
    .map(normalizedHeadingTitle)
    .filter(Boolean);
  if (requested.length === 0) throw new GatewayError(400, "invalid_heading_path");
  const parsed = parseHeadings(content);
  const candidates = parsed.headings.filter((heading) => {
    const candidate = heading.heading_path.split("::");
    if (candidate.length < requested.length) return false;
    return candidate.slice(-requested.length).every((part, index) => part === requested[index]);
  });
  if (candidates.length === 0) {
    throw new GatewayError(404, "heading_not_found", "Heading path was not found", {
      requested: requested.join("::"),
      available_headings: availableHeadingDetails(parsed.headings)
    });
  }
  if (candidates.length > 1) {
    throw new GatewayError(409, "heading_ambiguous", "Heading path matched more than one heading", {
      requested: requested.join("::"),
      matches: availableHeadingDetails(candidates)
    });
  }
  return { ...parsed, heading: candidates[0] };
}

export function sectionFromHeading(content, requestedPath, includeHeading = true) {
  const { lines, headings, heading } = resolveHeading(content, requestedPath);
  const start = includeHeading ? heading.line : heading.line + 1;
  const next = headings.find((candidate) => candidate.line > heading.line && candidate.level <= heading.level);
  const end = next?.line ?? lines.length;
  return {
    heading,
    start_line: start,
    end_line_exclusive: end,
    total_lines: lines.length,
    content: lines.slice(start, end).join("")
  };
}

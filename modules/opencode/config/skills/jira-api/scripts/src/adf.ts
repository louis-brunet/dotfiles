type AdfLinkMark = { type: "link"; attrs: { href: string } };
type AdfTextNode = { type: "text"; text: string; marks?: AdfLinkMark[] };
type AdfHardBreakNode = { type: "hardBreak" };
type AdfInlineNode = AdfTextNode | AdfHardBreakNode;
type AdfParagraphNode = { type: "paragraph"; content?: AdfInlineNode[] };
type AdfHeadingNode = { type: "heading"; attrs: { level: number }; content?: AdfInlineNode[] };
type AdfTaskState = "TODO" | "DONE";
type AdfTaskItemNode = {
  type: "taskItem";
  attrs: { localId: string; state: AdfTaskState };
  content?: AdfInlineNode[];
};
type AdfTaskListNode = {
  type: "taskList";
  attrs: { localId: string };
  content: AdfTaskItemNode[];
};
type AdfListItemNode = {
  type: "listItem";
  content: AdfParagraphNode[];
};
type AdfBulletListNode = { type: "bulletList"; content: AdfListItemNode[] };
type AdfOrderedListNode = { type: "orderedList"; content: AdfListItemNode[]; attrs?: { order: number } };
type AdfMediaNode = { type: "media"; attrs: { type: "external"; url: string; alt?: string } };
type AdfMediaSingleNode = { type: "mediaSingle"; attrs: { layout: "center" }; content: [AdfMediaNode] };
type AdfTopLevelNode =
  | AdfParagraphNode
  | AdfHeadingNode
  | AdfBulletListNode
  | AdfOrderedListNode
  | AdfTaskListNode
  | AdfMediaSingleNode;
export type AdfDoc = { type: "doc"; version: 1; content: AdfTopLevelNode[] };
type AdfParseState = { lines: string[]; index: number; nextLocalId: number };

export type MarkdownImage = {
  altText: string;
  target: string;
  start: number;
  end: number;
  raw: string;
};

const MARKDOWN_IMAGE_PATTERN = /!\[([^\]]*)\]\(([^)]+)\)/g;

export function descriptionToAdf(description: string): AdfDoc {
  const parsedAdfDocument = parseAdfDocument(description);
  if (parsedAdfDocument) {
    return parsedAdfDocument;
  }

  return textToAdf(normalizeStructuredText(description));
}

export function normalizeStructuredText(text: string): string {
  return text.replace(/\\([nrt\\])/g, (_match, escapeSequence: string) => {
    if (escapeSequence === "n") {
      return "\n";
    }

    if (escapeSequence === "r") {
      return "\r";
    }

    if (escapeSequence === "t") {
      return "\t";
    }

    return "\\";
  });
}

export function findMarkdownImages(text: string): MarkdownImage[] {
  const images: MarkdownImage[] = [];

  for (const match of text.matchAll(MARKDOWN_IMAGE_PATTERN)) {
    const start = match.index ?? -1;
    if (start < 0) {
      continue;
    }

    const raw = match[0];
    if (isInsideInlineCode(text, start)) {
      continue;
    }

    images.push({
      raw,
      altText: match[1].trim(),
      target: match[2].trim(),
      start,
      end: start + raw.length,
    });
  }

  return images;
}

function isInsideInlineCode(text: string, index: number): boolean {
  let inCode = false;

  for (let currentIndex = 0; currentIndex < index; currentIndex += 1) {
    if (text[currentIndex] === "`") {
      inCode = !inCode;
    }
  }

  return inCode;
}

function parseAdfDocument(description: string): AdfDoc | null {
  const trimmedDescription = description.trim();
  if (!trimmedDescription.startsWith("{")) {
    return null;
  }

  const parsedDescription = parseJson(trimmedDescription);
  if (!isAdfDocument(parsedDescription)) {
    return null;
  }

  return parsedDescription;
}

function isAdfDocument(value: unknown): value is AdfDoc {
  if (typeof value !== "object" || value === null) {
    return false;
  }

  const document = value as Record<string, unknown>;
  return document.type === "doc" && document.version === 1 && Array.isArray(document.content);
}

function textToAdf(text: string): AdfDoc {
  const state: AdfParseState = {
    lines: text.replace(/\r\n/g, "\n").split("\n"),
    index: 0,
    nextLocalId: 1,
  };
  const content: AdfTopLevelNode[] = [];

  while (state.index < state.lines.length) {
    const currentLine = state.lines[state.index];

    if (isBlankLine(currentLine)) {
      state.index += 1;
      continue;
    }

    const headingMatch = currentLine.match(/^(#{1,6})\s+(.*)$/);
    if (headingMatch) {
      content.push({
        type: "heading",
        attrs: { level: headingMatch[1].length },
        content: inlineTextToAdf(headingMatch[2].trim()),
      });
      state.index += 1;
      continue;
    }

    if (matchTaskLine(currentLine)) {
      content.push(parseTaskList(state));
      continue;
    }

    if (matchOrderedListLine(currentLine)) {
      content.push(parseOrderedList(state));
      continue;
    }

    if (matchBulletListLine(currentLine)) {
      content.push(parseBulletList(state));
      continue;
    }

    content.push(...parseParagraphNodes(state));
  }

  return {
    type: "doc",
    version: 1,
    content,
  };
}

function parseParagraphNodes(state: AdfParseState): AdfTopLevelNode[] {
  const paragraphLines: string[] = [];

  while (state.index < state.lines.length) {
    const currentLine = state.lines[state.index];
    if (isBlankLine(currentLine)) {
      break;
    }

    if (paragraphLines.length > 0 && isBlockStart(currentLine)) {
      break;
    }

    paragraphLines.push(currentLine.trim());
    state.index += 1;
  }

  return richTextToAdfNodes(paragraphLines);
}

function parseBulletList(state: AdfParseState): AdfBulletListNode {
  const items: AdfListItemNode[] = [];

  while (state.index < state.lines.length) {
    const match = matchBulletListLine(state.lines[state.index]);
    if (!match) {
      break;
    }

    items.push({
      type: "listItem",
      content: [createParagraph(match.text)],
    });
    state.index += 1;
  }

  return {
    type: "bulletList",
    content: items,
  };
}

function parseOrderedList(state: AdfParseState): AdfOrderedListNode {
  const items: AdfListItemNode[] = [];
  let firstOrder: number | null = null;

  while (state.index < state.lines.length) {
    const match = matchOrderedListLine(state.lines[state.index]);
    if (!match) {
      break;
    }

    if (firstOrder === null) {
      firstOrder = match.order;
    }

    items.push({
      type: "listItem",
      content: [createParagraph(match.text)],
    });
    state.index += 1;
  }

  return firstOrder && firstOrder > 1
    ? { type: "orderedList", attrs: { order: firstOrder }, content: items }
    : { type: "orderedList", content: items };
}

function parseTaskList(state: AdfParseState): AdfTaskListNode {
  const items: AdfTaskItemNode[] = [];

  while (state.index < state.lines.length) {
    const match = matchTaskLine(state.lines[state.index]);
    if (!match) {
      break;
    }

    items.push({
      type: "taskItem",
      attrs: {
        localId: nextLocalId(state, "task-item"),
        state: match.checked ? "DONE" : "TODO",
      },
      content: inlineTextToAdf(match.text),
    });
    state.index += 1;
  }

  return {
    type: "taskList",
    attrs: {
      localId: nextLocalId(state, "task-list"),
    },
    content: items,
  };
}

function richTextToAdfNodes(lines: string[]): AdfTopLevelNode[] {
  const nodes: AdfTopLevelNode[] = [];
  let paragraphBuffer: string[] = [];

  const flushParagraphBuffer = () => {
    if (paragraphBuffer.length === 0) {
      return;
    }

    nodes.push(createParagraph(paragraphBuffer.join("\n")));
    paragraphBuffer = [];
  };

  for (const line of lines) {
    const segments = splitLineByImages(line);
    const hasImages = segments.some((segment) => segment.type === "image");

    if (!hasImages) {
      paragraphBuffer.push(line);
      continue;
    }

    flushParagraphBuffer();

    for (const segment of segments) {
      if (segment.type === "text") {
        const trimmedText = segment.text.trim();
        if (trimmedText) {
          nodes.push(createParagraph(trimmedText));
        }
        continue;
      }

      nodes.push(createMediaSingle(segment.target, segment.altText));
    }
  }

  flushParagraphBuffer();

  return nodes.length > 0 ? nodes : [{ type: "paragraph" }];
}

function splitLineByImages(line: string): Array<{ type: "text"; text: string } | { type: "image"; target: string; altText: string }> {
  const segments: Array<{ type: "text"; text: string } | { type: "image"; target: string; altText: string }> = [];
  let lastIndex = 0;

  for (const image of findMarkdownImages(line)) {
    if (image.start > lastIndex) {
      segments.push({ type: "text", text: line.slice(lastIndex, image.start) });
    }

    segments.push({ type: "image", target: image.target, altText: image.altText });
    lastIndex = image.end;
  }

  if (lastIndex < line.length) {
    segments.push({ type: "text", text: line.slice(lastIndex) });
  }

  return segments;
}

function createMediaSingle(target: string, altText: string): AdfMediaSingleNode {
  return {
    type: "mediaSingle",
    attrs: { layout: "center" },
    content: [
      {
        type: "media",
        attrs: {
          type: "external",
          url: target,
          ...(altText ? { alt: altText } : {}),
        },
      },
    ],
  };
}

function isBlankLine(line: string): boolean {
  return line.trim() === "";
}

function isBlockStart(line: string): boolean {
  return /^(#{1,6})\s+/.test(line) || Boolean(matchTaskLine(line)) || Boolean(matchOrderedListLine(line)) || Boolean(matchBulletListLine(line));
}

function matchTaskLine(line: string): { checked: boolean; text: string } | null {
  const match = line.match(/^\s*[-*]\s+\[([ xX])\]\s+(.*)$/);
  if (!match) {
    return null;
  }

  return {
    checked: match[1].toLowerCase() === "x",
    text: match[2].trim(),
  };
}

function matchOrderedListLine(line: string): { order: number; text: string } | null {
  const match = line.match(/^\s*(\d+)\.\s+(.*)$/);
  if (!match) {
    return null;
  }

  return {
    order: Number(match[1]),
    text: match[2].trim(),
  };
}

function matchBulletListLine(line: string): { text: string } | null {
  if (matchTaskLine(line)) {
    return null;
  }

  const match = line.match(/^\s*[-*]\s+(.*)$/);
  if (!match) {
    return null;
  }

  return { text: match[1].trim() };
}

function createParagraph(text: string): AdfParagraphNode {
  const content = inlineTextToAdf(text);
  return content.length > 0 ? { type: "paragraph", content } : { type: "paragraph" };
}

function inlineTextToAdf(text: string): AdfInlineNode[] {
  const lines = text.split("\n");
  const content: AdfInlineNode[] = [];

  lines.forEach((line, index) => {
    if (line) {
      content.push(...inlineLineToAdf(line));
    }

    if (index < lines.length - 1) {
      content.push({ type: "hardBreak" });
    }
  });

  return content;
}

function inlineLineToAdf(line: string): AdfInlineNode[] {
  const content: AdfInlineNode[] = [];
  const markdownLinkPattern = /\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)/g;
  let lastIndex = 0;

  for (const match of line.matchAll(markdownLinkPattern)) {
    const fullMatch = match[0];
    const linkText = match[1];
    const href = match[2];
    const matchIndex = match.index ?? -1;

    if (matchIndex < 0) {
      continue;
    }

    if (matchIndex > lastIndex) {
      content.push({ type: "text", text: line.slice(lastIndex, matchIndex) });
    }

    content.push({
      type: "text",
      text: linkText,
      marks: [{ type: "link", attrs: { href } }],
    });

    lastIndex = matchIndex + fullMatch.length;
  }

  if (lastIndex < line.length) {
    content.push({ type: "text", text: line.slice(lastIndex) });
  }

  return content;
}

function nextLocalId(state: AdfParseState, prefix: string): string {
  const localId = `${prefix}-${state.nextLocalId}`;
  state.nextLocalId += 1;
  return localId;
}

function parseJson(bodyText: string): unknown | null {
  if (!bodyText) {
    return null;
  }

  try {
    return JSON.parse(bodyText) as unknown;
  } catch {
    return null;
  }
}

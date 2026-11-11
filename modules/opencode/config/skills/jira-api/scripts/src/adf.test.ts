import test from "node:test";
import assert from "node:assert/strict";

import { descriptionToAdf, findMarkdownImages, normalizeStructuredText } from "./adf.ts";

test("descriptionToAdf converts remote markdown images to mediaSingle blocks", () => {
  const document = descriptionToAdf("Intro\n\n![Architecture](https://example.com/diagram.png)\n\nOutro");

  assert.deepEqual(document.content, [
    {
      type: "paragraph",
      content: [{ type: "text", text: "Intro" }],
    },
    {
      type: "mediaSingle",
      attrs: { layout: "center" },
      content: [
        {
          type: "media",
          attrs: {
            type: "external",
            url: "https://example.com/diagram.png",
            alt: "Architecture",
          },
        },
      ],
    },
    {
      type: "paragraph",
      content: [{ type: "text", text: "Outro" }],
    },
  ]);
});

test("descriptionToAdf preserves markdown links alongside image parsing", () => {
  const document = descriptionToAdf("See [spec](https://example.com/spec) before ![Diagram](https://example.com/diagram.png)");

  assert.deepEqual(document.content, [
    {
      type: "paragraph",
      content: [
        { type: "text", text: "See " },
        {
          type: "text",
          text: "spec",
          marks: [{ type: "link", attrs: { href: "https://example.com/spec" } }],
        },
        { type: "text", text: " before" },
      ],
    },
    {
      type: "mediaSingle",
      attrs: { layout: "center" },
      content: [
        {
          type: "media",
          attrs: {
            type: "external",
            url: "https://example.com/diagram.png",
            alt: "Diagram",
          },
        },
      ],
    },
  ]);
});

test("findMarkdownImages identifies local and remote image targets", () => {
  const images = findMarkdownImages("![Remote](https://example.com/a.png) and ![Local](./b.png)");

  assert.deepEqual(
    images.map((image) => ({ altText: image.altText, target: image.target })),
    [
      { altText: "Remote", target: "https://example.com/a.png" },
      { altText: "Local", target: "./b.png" },
    ],
  );
});

test("findMarkdownImages ignores markdown image examples inside inline code", () => {
  const images = findMarkdownImages("Use `![Example](./screenshot.png)` in docs, not live content.");

  assert.deepEqual(images, []);
});

test("findMarkdownImages still detects local markdown images outside inline code", () => {
  const images = findMarkdownImages("Create issue with `![Example](./docs-only.png)` in docs and real asset ![Upload](./real.png)");

  assert.deepEqual(
    images.map((image) => ({ altText: image.altText, target: image.target })),
    [{ altText: "Upload", target: "./real.png" }],
  );
});

test("normalizeStructuredText converts escaped newlines in structured text", () => {
  assert.equal(normalizeStructuredText("Line 1\\n\\nLine 2"), "Line 1\n\nLine 2");
});

test("normalizeStructuredText preserves double-escaped newline as literal backslash-n", () => {
  assert.equal(normalizeStructuredText("Literal \\\\n marker"), "Literal \\n marker");
});

test("descriptionToAdf treats literal escaped newlines as real line breaks for structured text", () => {
  const document = descriptionToAdf("# Heading\\n\\nParagraph");

  assert.deepEqual(document.content, [
    {
      type: "heading",
      attrs: { level: 1 },
      content: [{ type: "text", text: "Heading" }],
    },
    {
      type: "paragraph",
      content: [{ type: "text", text: "Paragraph" }],
    },
  ]);
});

test("descriptionToAdf preserves explicit raw ADF JSON payloads", () => {
  const document = descriptionToAdf('{"type":"doc","version":1,"content":[{"type":"paragraph","content":[{"type":"text","text":"Line 1\\nLine 2"}]}]}');

  assert.deepEqual(document, {
    type: "doc",
    version: 1,
    content: [
      {
        type: "paragraph",
        content: [{ type: "text", text: "Line 1\nLine 2" }],
      },
    ],
  });
});

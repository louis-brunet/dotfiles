# Jira ADF Reference

Use this file only when you need to send explicit Atlassian Document Format (ADF) JSON to Jira.

For normal ticket refinement flows, prefer structured ticket text and let the Jira API skill convert it into Jira-native headings, paragraphs, bullet lists, ordered lists, task lists, and supported image blocks.

Read this file before composing explicit ADF when:

- you need exact control over the Jira description structure
- you need richer nodes such as `codeBlock`
- the built-in text-to-ADF conversion is not sufficient for the update you want to send

## Built-in markdown image support

The local `jira-api` script supports markdown image syntax in structured text updates:

- remote images: `![Architecture](https://example.com/diagram.png)`
- local images during issue-scoped updates and comments: `![Screenshot](./screenshot.png)`

Practical behavior:

- Remote images are converted into Jira `mediaSingle` blocks using an external URL.
- Local images are uploaded as Jira attachments during `issue update-description` and `issue add-comment`, then rewritten to the returned attachment content URL before ADF conversion.
- Local images are also supported during `issue create`, but that flow is implemented as: create issue, upload attachments, then update the created issue description.
- Because `issue create` with local images is multi-step, a post-create failure can leave a successfully created issue whose description was not fully updated. The CLI reports that partial-success condition explicitly.
- When a line mixes text and an image, the converter emits the surrounding text as paragraphs and the image as its own `mediaSingle` block.

If you need a more advanced media layout than the built-in markdown path supports, compose explicit ADF JSON.

## Minimal document shape

Every Jira description payload must be a root `doc` node:

```json
{
  "type": "doc",
  "version": 1,
  "content": []
}
```

`content` contains top-level block nodes such as headings, paragraphs, lists, task lists, media blocks, and code blocks.

### Media single with external image

This is the ADF shape validated by the local ADRP Jira instance for markdown image rendering:

```json
{
  "type": "mediaSingle",
  "attrs": {
    "layout": "center"
  },
  "content": [
    {
      "type": "media",
      "attrs": {
        "type": "external",
        "url": "https://example.com/diagram.png",
        "alt": "Architecture"
      }
    }
  ]
}
```

For local images, the built-in CLI flow uploads the file first and then uses the returned Jira attachment content URL in the same shape.

## Core block nodes

### Heading

Use headings for section titles. Levels run from 1 to 6.

```json
{
  "type": "heading",
  "attrs": {
    "level": 2
  },
  "content": [
    {
      "type": "text",
      "text": "Acceptance Criteria"
    }
  ]
}
```

### Paragraph

Use paragraphs for normal prose.

```json
{
  "type": "paragraph",
  "content": [
    {
      "type": "text",
      "text": "Implement a reusable Jira API skill for issue lookup and description updates."
    }
  ]
}
```

For line breaks inside one paragraph, use `hardBreak` between text nodes:

```json
{
  "type": "paragraph",
  "content": [
    {
      "type": "text",
      "text": "First line"
    },
    {
      "type": "hardBreak"
    },
    {
      "type": "text",
      "text": "Second line"
    }
  ]
}
```

### Bullet list and list items

Use `bulletList` for unordered items. Each item is a `listItem` containing one or more paragraphs.

```json
{
  "type": "bulletList",
  "content": [
    {
      "type": "listItem",
      "content": [
        {
          "type": "paragraph",
          "content": [
            {
              "type": "text",
              "text": "As a developer, I want to fetch a Jira issue by key."
            }
          ]
        }
      ]
    },
    {
      "type": "listItem",
      "content": [
        {
          "type": "paragraph",
          "content": [
            {
              "type": "text",
              "text": "As a developer, I want to run JQL searches."
            }
          ]
        }
      ]
    }
  ]
}
```

### Ordered list and list items

Use `orderedList` for numbered steps or ranked items. `attrs.order` is optional and sets the starting number.

```json
{
  "type": "orderedList",
  "attrs": {
    "order": 1
  },
  "content": [
    {
      "type": "listItem",
      "content": [
        {
          "type": "paragraph",
          "content": [
            {
              "type": "text",
              "text": "Fetch the remote issue."
            }
          ]
        }
      ]
    },
    {
      "type": "listItem",
      "content": [
        {
          "type": "paragraph",
          "content": [
            {
              "type": "text",
              "text": "Generate the local refined ticket."
            }
          ]
        }
      ]
    }
  ]
}
```

### Task list and task items

Use `taskList` for Jira checklists. `taskList.attrs.localId` is required. Each `taskItem` also needs a required `localId` and a `state` of `TODO` or `DONE`.

```json
{
  "type": "taskList",
  "attrs": {
    "localId": "acceptance-criteria"
  },
  "content": [
    {
      "type": "taskItem",
      "attrs": {
        "localId": "ac-1",
        "state": "TODO"
      },
      "content": [
        {
          "type": "text",
          "text": "The CLI can fetch issue details for a known key."
        }
      ]
    },
    {
      "type": "taskItem",
      "attrs": {
        "localId": "ac-2",
        "state": "DONE"
      },
      "content": [
        {
          "type": "text",
          "text": "Authentication variables are documented."
        }
      ]
    }
  ]
}
```

Use simple stable strings for `localId`. They only need to be unique within the document.

### Code block

Use `codeBlock` when you need a real Jira code block instead of plain paragraph text.

```json
{
  "type": "codeBlock",
  "attrs": {
    "language": "bash"
  },
  "content": [
    {
      "type": "text",
      "text": "jira-api issue get ADRP-1"
    }
  ]
}
```

## Full example

This is a complete Jira description payload combining headings, paragraphs, bullet lists, and a task list:

```json
{
  "type": "doc",
  "version": 1,
  "content": [
    {
      "type": "heading",
      "attrs": {
        "level": 1
      },
      "content": [
        {
          "type": "text",
          "text": "Add Jira API Interaction Skill"
        }
      ]
    },
    {
      "type": "heading",
      "attrs": {
        "level": 2
      },
      "content": [
        {
          "type": "text",
          "text": "Summary"
        }
      ]
    },
    {
      "type": "paragraph",
      "content": [
        {
          "type": "text",
          "text": "Implement a reusable Jira API interaction skill that supports search, issue lookup, and description updates."
        }
      ]
    },
    {
      "type": "heading",
      "attrs": {
        "level": 2
      },
      "content": [
        {
          "type": "text",
          "text": "User stories"
        }
      ]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [
                {
                  "type": "text",
                  "text": "As a developer, I want to fetch a Jira issue by key."
                }
              ]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [
                {
                  "type": "text",
                  "text": "As a developer, I want to run JQL searches."
                }
              ]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": {
        "level": 2
      },
      "content": [
        {
          "type": "text",
          "text": "Acceptance Criteria"
        }
      ]
    },
    {
      "type": "taskList",
      "attrs": {
        "localId": "acceptance-criteria"
      },
      "content": [
        {
          "type": "taskItem",
          "attrs": {
            "localId": "ac-1",
            "state": "TODO"
          },
          "content": [
            {
              "type": "text",
              "text": "A documented Jira API skill exists with clear usage and command contracts."
            }
          ]
        },
        {
          "type": "taskItem",
          "attrs": {
            "localId": "ac-2",
            "state": "TODO"
          },
          "content": [
            {
              "type": "text",
              "text": "The CLI supports description updates using ADF."
            }
          ]
        }
      ]
    }
  ]
}
```

## Shell usage pattern

When sending explicit ADF through the local CLI, use a heredoc so the JSON stays valid as one shell argument:

```bash
DOC=$(cat <<'EOF'
{
  "type": "doc",
  "version": 1,
  "content": [
    {
      "type": "heading",
      "attrs": {
        "level": 1
      },
      "content": [
        {
          "type": "text",
          "text": "Example"
        }
      ]
    }
  ]
}
EOF
)

jira-api issue update-description ADRP-123 "$DOC"
```

## Decision rule

- Use structured plain ticket text for ordinary refinement syncs.
- Use explicit ADF when you need exact node control or nodes the built-in converter does not create.
- Do not send markdown markers as literal text and call that "formatted".

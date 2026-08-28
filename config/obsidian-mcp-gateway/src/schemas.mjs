import * as z from "zod/v4";

export const operationIdSchema = z
  .string()
  .min(8)
  .max(128)
  .regex(/^[A-Za-z0-9._-]+$/, "operation_id contains unsupported characters");

export const namespaceSchema = z.enum(["main", "pilot", "both"]);

export const knowledgeFileSchema = z
  .object({
    namespace: z.enum(["main", "pilot"]),
    path: z.string().min(1).max(1024)
  })
  .strict();

export const knowledgeListSchema = z
  .object({
    namespace: namespaceSchema.default("both"),
    path_prefix: z.string().max(1024).default("Notes/"),
    limit: z.number().int().min(1).max(500).default(100)
  })
  .strict();

export const knowledgeSearchSchema = z
  .object({
    query: z.string().trim().min(1).max(512),
    namespace: namespaceSchema.default("both"),
    limit: z.number().int().min(1).max(100).default(20)
  })
  .strict();

export const knowledgeReadSchema = z
  .object({
    namespace: z.enum(["main", "pilot"]),
    path: z.string().min(1).max(1024),
    start_line: z.number().int().min(0).optional(),
    line_limit: z.number().int().min(1).max(10_000).optional()
  })
  .strict();

export const knowledgeBatchReadSchema = z
  .object({
    files: z.array(knowledgeFileSchema).min(1).max(20),
    max_total_chars: z.number().int().min(1_000).max(200_000).default(50_000)
  })
  .strict();

export const knowledgeFrontmatterSchema = knowledgeFileSchema;

export const knowledgeOutlineSchema = knowledgeFileSchema;

export const knowledgeSectionReadSchema = z
  .object({
    namespace: z.enum(["main", "pilot"]),
    path: z.string().min(1).max(1024),
    heading_path: z.string().trim().min(1).max(1024),
    include_heading: z.boolean().default(true)
  })
  .strict();

export const knowledgeTagSearchSchema = z
  .object({
    tag: z.string().trim().min(1).max(100),
    namespace: namespaceSchema.default("both"),
    limit: z.number().int().min(1).max(100).default(20)
  })
  .strict();

export const attachmentUploadSchema = z
  .object({
    source_path: z.string().min(1).max(4096),
    operation_id: operationIdSchema,
    display_name: z.string().min(1).max(255).optional()
  })
  .strict();

export const attachmentPreviewSchema = z
  .object({
    attachment_id: z.string().regex(/^att_[a-f0-9]{64}$/).optional(),
    path: z.string().min(1).max(1024).optional()
  })
  .strict()
  .refine((value) => Boolean(value.attachment_id) !== Boolean(value.path), "exactly one of attachment_id or path is required");

const attachmentIdsSchema = z
  .array(z.string().regex(/^att_[a-f0-9]{64}$/))
  .max(64)
  .optional();

export const recordCreateSchema = z
  .object({
    title: z.string().trim().min(1).max(180),
    body: z.string().trim().min(1).max(1_000_000),
    tags: z.array(z.string().trim().min(1).max(100)).min(1).max(64),
    project: z.string().trim().min(1).max(120).optional(),
    attachment_ids: attachmentIdsSchema,
    operation_id: operationIdSchema
  })
  .strict();

export const recordAppendSchema = z
  .object({
    record_id: z.string().uuid(),
    body: z.string().max(1_000_000).default(""),
    attachment_ids: attachmentIdsSchema,
    operation_id: operationIdSchema
  })
  .strict()
  .refine(
    (value) => value.body.trim().length > 0 || (value.attachment_ids?.length ?? 0) > 0,
    "body or attachment_ids is required"
  );

export function parseOrThrow(schema, value) {
  const parsed = schema.safeParse(value);
  if (!parsed.success) {
    const details = parsed.error.issues.map((issue) => ({
      path: issue.path.join("."),
      message: issue.message
    }));
    const error = new Error("invalid_request");
    error.status = 400;
    error.code = "invalid_request";
    error.details = details;
    throw error;
  }
  return parsed.data;
}

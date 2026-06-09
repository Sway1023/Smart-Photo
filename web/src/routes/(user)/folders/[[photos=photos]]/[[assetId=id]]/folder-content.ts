import { normalizeTreePath } from '$lib/utils/tree-utils';

export type FolderBreadcrumb = {
  label: string;
  path: string;
};

export const getFolderLabel = (folder: string) => {
  const normalized = normalizeTreePath(folder);
  const segments = normalized.split('/').filter(Boolean);
  return (segments.at(-1) ?? normalized) || '/';
};

/** One trail entry per folder navigation step (not every path segment). */
export const resolveBreadcrumbTrail = (trail: FolderBreadcrumb[], path: string): FolderBreadcrumb[] => {
  const normalized = normalizeTreePath(path);
  if (!normalized) {
    return trail.length === 0 ? trail : [];
  }

  const node: FolderBreadcrumb = { label: getFolderLabel(normalized), path: normalized };
  const last = trail.at(-1);

  if (last?.path === normalized) {
    return trail;
  }

  if (last && normalized.startsWith(`${last.path}/`)) {
    return [...trail, node];
  }

  const existingIndex = trail.findIndex((crumb) => crumb.path === normalized);
  if (existingIndex >= 0) {
    return trail.slice(0, existingIndex + 1);
  }

  return [node];
};

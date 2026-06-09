import { eventManager } from '$lib/managers/event-manager.svelte';
import { TreeNode } from '$lib/utils/tree-utils';
import {
  getAssetsByOriginalPath,
  getUniqueOriginalPaths,
  /**
   * TODO: Incorrect type
   */
  type AssetResponseDto,
} from '@immich/sdk';

type AssetCache = {
  [path: string]: AssetResponseDto[];
};

class FoldersStore {
  folders = $state.raw<TreeNode | null>(null);
  private initialized = false;
  private assets = $state<AssetCache>({});
  private readonly externalOnly = true;

  constructor() {
    eventManager.on({
      AuthLogout: () => this.clearCache(),
    });
  }

  async fetchTree(): Promise<TreeNode> {
    if (this.initialized) {
      return this.folders!;
    }
    this.folders = TreeNode.fromPaths(await getUniqueOriginalPaths({ externalOnly: this.externalOnly }));
    this.folders.collapse();
    this.initialized = true;
    return this.folders;
  }

  bustAssetCache() {
    this.assets = {};
  }

  async refreshAssetsByPath(path: string) {
    return (this.assets[path] = await getAssetsByOriginalPath({ path, externalOnly: this.externalOnly }));
  }

  async fetchAssetsByPath(path: string) {
    return (this.assets[path] ??= await getAssetsByOriginalPath({ path, externalOnly: this.externalOnly }));
  }

  clearCache() {
    this.initialized = false;
    this.assets = {};
    this.folders = null;
  }
}

export const foldersStore = new FoldersStore();

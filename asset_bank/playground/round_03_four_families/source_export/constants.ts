import {SpriteConfig} from './utils/helper';

/**
 * Configuration for RPG Premium - Dimensional Conqueror
 */
export const CONFIG = {
  // Game Title and Base Canvas
  title: {
    value: 'RPG Premium: Dimensional Conqueror',
    type: 'string',
    label: 'Game Title',
    group: 'GAME',
  },
  baseCanvasWidth: {
    value: 1280,
    type: 'number',
    label: 'Base Canvas Width',
    group: 'GAME',
  },
  baseCanvasHeight: {
    value: 720,
    type: 'number',
    label: 'Base Canvas Height',
    group: 'GAME',
  },

  // System
  targetFPS: {
    value: 60,
    type: 'number',
    label: 'Target FPS',
    group: 'SYSTEM',
  },
  stepMs: {
    value: 1000 / 60,
    type: 'number',
    label: 'Step MS',
    group: 'SYSTEM',
  },
  maxSubSteps: {
    value: 5,
    type: 'number',
    label: 'Max Sub Steps',
    group: 'SYSTEM',
  },

  // Theme
  backgroundColor: {
    value: '#090a10',
    type: 'color',
    label: 'Background Color',
    group: 'THEME',
  },
  primaryColor: {
    value: '#38bdf8',
    type: 'color',
    label: 'Primary Color',
    group: 'THEME',
  },
  accentColor: {
    value: '#f59e0b',
    type: 'color',
    label: 'Accent Color',
    group: 'THEME',
  },
  fontFamily: {
    value: "'Cinzel', 'Trajan Pro', 'Cinzel Decorative', serif, sans-serif",
    type: 'string',
    label: 'Font Family',
    group: 'THEME',
  },

  // Audio Levels
  defaultMusicVolume: {
    value: 0.5,
    type: 'number',
    label: 'Default Music Volume',
    group: 'AUDIO',
  },
  defaultSfxVolume: {
    value: 0.6,
    type: 'number',
    label: 'Default SFX Volume',
    group: 'AUDIO',
  },

  // Gameplay Tuning & Difficulty
  playerMaxHealth: {
    value: 100,
    type: 'number',
    label: 'Player Max Health',
    group: 'Rules',
  },
  playerSpeed: {
    value: 260,
    type: 'number',
    label: 'Player Speed',
    group: 'Physics',
  },
  dashSpeed: {
    value: 650,
    type: 'number',
    label: 'Dash Speed',
    group: 'Physics',
  },
  dashCooldown: {
    value: 0.8,
    type: 'number',
    label: 'Dash Cooldown (s)',
    group: 'Rules',
  },
  playerAttackDamage: {
    value: 30,
    type: 'number',
    label: 'Player Base Attack Damage',
    group: 'Rules',
  },
  enemySpawnRate: {
    value: 1.0,
    type: 'number',
    label: 'Enemy Spawn Rate Multiplier',
    group: 'Rules',
  },
  bossHealthMultiplier: {
    value: 1.0,
    type: 'number',
    label: 'Boss Health Multiplier',
    group: 'Rules',
  },

  // Asset configurations (Aspect ratios and dimensions from discovery metadata)
  wpnScarletSaberAspect: { value: 668 / 669, type: 'number', label: 'Scarlet Saber Aspect', group: 'ASSETS' },
  wpnArcBlasterAspect: { value: 722 / 711, type: 'number', label: 'Arc Blaster Aspect', group: 'ASSETS' },
  wpnPulseRifleAspect: { value: 857 / 321, type: 'number', label: 'Pulse Rifle Aspect', group: 'ASSETS' },
  wpnJadeSpearAspect: { value: 906 / 895, type: 'number', label: 'Jade Spear Aspect', group: 'ASSETS' },
  wpnCrystalStaffAspect: { value: 579 / 666, type: 'number', label: 'Crystal Staff Aspect', group: 'ASSETS' },
  wpnEmberCannonAspect: { value: 762 / 504, type: 'number', label: 'Ember Cannon Aspect', group: 'ASSETS' },
  wpnSingularityCannonAspect: { value: 823 / 536, type: 'number', label: 'Singularity Cannon Aspect', group: 'ASSETS' },
  wpnRiftBladeAspect: { value: 745 / 751, type: 'number', label: 'Rift Blade Aspect', group: 'ASSETS' },

  envRobotReactorAspect: { value: 538 / 782, type: 'number', label: 'Robot Reactor Aspect', group: 'ASSETS' },
  envRobotTerminalAspect: { value: 768 / 772, type: 'number', label: 'Robot Terminal Aspect', group: 'ASSETS' },
  envJadePillarAspect: { value: 465 / 844, type: 'number', label: 'Jade Pillar Aspect', group: 'ASSETS' },
  envJadeCrystalAspect: { value: 618 / 792, type: 'number', label: 'Jade Crystal Aspect', group: 'ASSETS' },
  envJadeShrineAspect: { value: 660 / 598, type: 'number', label: 'Jade Shrine Aspect', group: 'ASSETS' },
  envScarletBrazierAspect: { value: 618 / 690, type: 'number', label: 'Scarlet Brazier Aspect', group: 'ASSETS' },
  envScarletBarricadeAspect: { value: 783 / 727, type: 'number', label: 'Scarlet Barricade Aspect', group: 'ASSETS' },
  envScarletBannerAspect: { value: 424 / 904, type: 'number', label: 'Scarlet Banner Aspect', group: 'ASSETS' },
  envRiftObeliskAspect: { value: 454 / 812, type: 'number', label: 'Rift Obelisk Aspect', group: 'ASSETS' },
  envRiftShardAspect: { value: 566 / 700, type: 'number', label: 'Rift Shard Aspect', group: 'ASSETS' },
  envRiftPortalAspect: { value: 782 / 752, type: 'number', label: 'Rift Portal Aspect', group: 'ASSETS' },

  vfxEmpPulseAspect: { value: 845 / 657, type: 'number', label: 'EMP Pulse Aspect', group: 'ASSETS' },
  vfxEmberExplosionAspect: { value: 782 / 722, type: 'number', label: 'Ember Explosion Aspect', group: 'ASSETS' },
  vfxVoidOrbAspect: { value: 680 / 679, type: 'number', label: 'Void Orb Aspect', group: 'ASSETS' },
  vfxDistortionBeamAspect: { value: 846 / 825, type: 'number', label: 'Distortion Beam Aspect', group: 'ASSETS' },
  vfxElectricBoltAspect: { value: 866 / 508, type: 'number', label: 'Electric Bolt Aspect', group: 'ASSETS' },
  vfxScarletSlashAspect: { value: 782 / 536, type: 'number', label: 'Scarlet Slash Aspect', group: 'ASSETS' },
  vfxEmeraldBeamAspect: { value: 690 / 816, type: 'number', label: 'Emerald Beam Aspect', group: 'ASSETS' },
  vfxSparkBurstAspect: { value: 782 / 629, type: 'number', label: 'Spark Burst Aspect', group: 'ASSETS' },
  vfxFlameShotAspect: { value: 680 / 454, type: 'number', label: 'Flame Shot Aspect', group: 'ASSETS' },
  vfxLeafSlashAspect: { value: 711 / 722, type: 'number', label: 'Leaf Slash Aspect', group: 'ASSETS' },
  vfxRootSnareAspect: { value: 822 / 715, type: 'number', label: 'Root Snare Aspect', group: 'ASSETS' },
  vfxRealityFractureAspect: { value: 1.0, type: 'number', label: 'Reality Fracture Aspect', group: 'ASSETS' },

  riftSkitterAspect: { value: 815 / 763, type: 'number', label: 'Rift Skitter Aspect', group: 'ASSETS' },
  roboticDroneAspect: { value: 651 / 498, type: 'number', label: 'Robotic Drone Aspect', group: 'ASSETS' },

  playerSprite: {
    value: undefined as SpriteConfig | undefined,
    type: 'sprite',
    label: 'Player Sprite',
    group: 'Visuals',
  },
};

// Merge customized config values if present (injected by Playground)
const {playgroundConfig} = globalThis as {
  playgroundConfig?: Record<string, unknown>;
};
if (playgroundConfig) {
  for (const [key, value] of Object.entries(playgroundConfig)) {
    if (key in CONFIG) {
      Object.assign(CONFIG[key as keyof typeof CONFIG], {value});
    }
  }
}

/**
 * Type helper for reading values in game code
 */
export type ConfigKey = keyof typeof CONFIG;

/**
 * Gets a configuration value by key.
 * @param key The configuration key.
 * @return The configuration value.
 */
export function getConfig<K extends ConfigKey>(
  key: K,
): (typeof CONFIG)[K]['value'] {
  return CONFIG[key].value;
}

export const THEME = {
  fontFamily: "'Cinzel', 'Cinzel Decorative', serif",
  colors: {
    robotic: {
      primary: '#06b6d4',
      bg: '#0f172a',
      accent: '#eab308',
      border: '#0891b2',
    },
    jade: {
      primary: '#10b981',
      bg: '#064e3b',
      accent: '#fbbf24',
      border: '#059669',
    },
    scarlet: {
      primary: '#ef4444',
      bg: '#450a0a',
      accent: '#f97316',
      border: '#b91c1c',
    },
    rift: {
      primary: '#c084fc',
      bg: '#2e1065',
      accent: '#38bdf8',
      border: '#9333ea',
    },
  },
};

// tslint:disable
/* eslint-disable */
import React, {useCallback, useEffect, useRef, useState} from 'react';
import {
  Play,
  RotateCw,
  Pause,
  Volume2,
  VolumeX,
  Menu as MenuIcon,
  X,
  Zap,
  Shield,
  Heart,
  Sparkles,
  Trophy,
  ArrowLeft,
  Flame,
  Swords,
  ChevronRight,
  Info,
} from 'lucide-react';
import {getConfig, THEME} from './constants';
import BackgroundMusic from './utils/BackgroundMusic';
import {
  createFixedStepper,
  drawAsset,
  formatTime,
  GameState,
  MenuOverlay,
  Overlay,
  prepareCanvas,
  useAssets,
  useAutoFocus,
  useInput,
  useIsMobile,
  gameAudio,
} from './utils/helper';
import {
  usePlayground,
  usePlaygroundGameLifecycle,
  useRpc,
} from './utils/usePlayground';
import {SpriteRenderer, SpriteActionConfig, SpriteAnimationState} from './SpriteRenderer';

// Background music track selection
const BACKGROUND_MUSIC_URL = 'https://storage.googleapis.com/assets-gen-playground/musiclibrary/grid_runner.mp3';

// Biome definitions
export type BiomeType = 'robotic' | 'jade' | 'scarlet' | 'rift';

interface BiomeInfo {
  id: BiomeType;
  name: string;
  subtitle: string;
  floorAsset: string;
  primaryColor: string;
  accentColor: string;
  bossName: string;
  requiredKills: number;
}

const BIOMES: BiomeInfo[] = [
  {
    id: 'robotic',
    name: 'Sector 07: Robotic Foundry',
    subtitle: 'Cybernetic Assembly & EMP Overload',
    floorAsset: 'env_robot_floor',
    primaryColor: '#06b6d4',
    accentColor: '#eab308',
    bossName: 'Assembly Overseer',
    requiredKills: 12,
  },
  {
    id: 'jade',
    name: 'Sanctuary of Jade Moss',
    subtitle: 'Ancient Stone & Emerald Wardens',
    floorAsset: 'env_jade_floor',
    primaryColor: '#10b981',
    accentColor: '#34d399',
    bossName: 'Emerald Warden',
    requiredKills: 15,
  },
  {
    id: 'scarlet',
    name: 'Scarlet Fortress of Ash',
    subtitle: 'Crimson Duelists & Molten Hounds',
    floorAsset: 'env_scarlet_floor',
    primaryColor: '#ef4444',
    accentColor: '#f97316',
    bossName: 'Crimson Castellan',
    requiredKills: 18,
  },
  {
    id: 'rift',
    name: 'Interdimensional Void Rift',
    subtitle: 'Fractured Space & Cosmic Singularity',
    floorAsset: 'env_rift_floor',
    primaryColor: '#c084fc',
    accentColor: '#38bdf8',
    bossName: 'Paradox Monarch',
    requiredKills: 20,
  },
];

// Weapon Archetypes
interface WeaponConfig {
  id: string;
  name: string;
  assetId: string;
  vfxAssetId: string;
  type: 'projectile' | 'melee' | 'beam' | 'vortex';
  damage: number;
  cooldown: number;
  speed: number;
  range: number;
  color: string;
  description: string;
}

const WEAPONS: WeaponConfig[] = [
  {
    id: 'arc_blaster',
    name: 'Arc Blaster',
    assetId: 'wpn_arc_blaster',
    vfxAssetId: 'vfx_electric_bolt',
    type: 'projectile',
    damage: 32,
    cooldown: 0.18,
    speed: 750,
    range: 650,
    color: '#06b6d4',
    description: 'Rapid twin high-voltage plasma bolts.',
  },
  {
    id: 'pulse_rifle',
    name: 'Pulse Rifle',
    assetId: 'wpn_pulse_rifle',
    vfxAssetId: 'vfx_spark_burst',
    type: 'beam',
    damage: 48,
    cooldown: 0.28,
    speed: 1100,
    range: 750,
    color: '#38bdf8',
    description: 'Penetrating hyper-kinetic pulse beams.',
  },
  {
    id: 'jade_spear',
    name: 'Jade Spear',
    assetId: 'wpn_jade_spear',
    vfxAssetId: 'vfx_leaf_slash',
    type: 'melee',
    damage: 55,
    cooldown: 0.25,
    speed: 550,
    range: 160,
    color: '#10b981',
    description: 'Long-range sacred thrust with spiraling leaf gale.',
  },
  {
    id: 'crystal_staff',
    name: 'Crystal Staff',
    assetId: 'wpn_crystal_staff',
    vfxAssetId: 'vfx_root_snare',
    type: 'projectile',
    damage: 38,
    cooldown: 0.22,
    speed: 620,
    range: 600,
    color: '#34d399',
    description: 'Homing crystal starbursts that snare foes.',
  },
  {
    id: 'scarlet_saber',
    name: 'Scarlet Saber',
    assetId: 'wpn_scarlet_saber',
    vfxAssetId: 'vfx_scarlet_slash',
    type: 'melee',
    damage: 70,
    cooldown: 0.22,
    speed: 600,
    range: 150,
    color: '#ef4444',
    description: 'Devastating fiery slash arc with blazing bleed.',
  },
  {
    id: 'ember_cannon',
    name: 'Ember Cannon',
    assetId: 'wpn_ember_cannon',
    vfxAssetId: 'vfx_ember_explosion',
    type: 'projectile',
    damage: 85,
    cooldown: 0.55,
    speed: 520,
    range: 580,
    color: '#f97316',
    description: 'Heavy explosive mortar causing wide radial blast.',
  },
  {
    id: 'rift_blade',
    name: 'Rift Blade',
    assetId: 'wpn_rift_blade',
    vfxAssetId: 'vfx_reality_fracture',
    type: 'melee',
    damage: 65,
    cooldown: 0.2,
    speed: 700,
    range: 170,
    color: '#a855f7',
    description: 'Reality-tearing spatial slash slicing dimensions.',
  },
  {
    id: 'singularity_cannon',
    name: 'Singularity Cannon',
    assetId: 'wpn_singularity_cannon',
    vfxAssetId: 'vfx_void_orb',
    type: 'vortex',
    damage: 40,
    cooldown: 0.6,
    speed: 400,
    range: 550,
    color: '#c084fc',
    description: 'Swirling gravitational sphere pulling enemies inward.',
  },
];

// Manifest mapping all discovered assets
const ASSETS_MANIFEST: Record<string, string> = {
  wpn_scarlet_saber: 'assets/images/wpn_scarlet_saber.png',
  wpn_arc_blaster: 'assets/images/wpn_arc_blaster.png',
  wpn_pulse_rifle: 'assets/images/wpn_pulse_rifle.png',
  wpn_jade_spear: 'assets/images/wpn_jade_spear.png',
  wpn_crystal_staff: 'assets/images/wpn_crystal_staff.png',
  wpn_ember_cannon: 'assets/images/wpn_ember_cannon.png',
  wpn_singularity_cannon: 'assets/images/wpn_singularity_cannon.png',
  wpn_rift_blade: 'assets/images/wpn_rift_blade.png',

  env_robot_reactor: 'assets/images/env_robot_reactor.png',
  env_robot_terminal: 'assets/images/env_robot_terminal.png',
  env_robot_hazard_panel: 'assets/images/env_robot_hazard_panel.png',
  env_robot_floor: 'assets/images/env_robot_floor.png',

  env_jade_pillar: 'assets/images/env_jade_pillar.png',
  env_jade_crystal: 'assets/images/env_jade_crystal.png',
  env_jade_shrine: 'assets/images/env_jade_shrine.png',
  env_jade_floor: 'assets/images/env_jade_floor.png',

  env_scarlet_brazier: 'assets/images/env_scarlet_brazier.png',
  env_scarlet_barricade: 'assets/images/env_scarlet_barricade.png',
  env_scarlet_banner: 'assets/images/env_scarlet_banner.png',
  env_scarlet_floor: 'assets/images/env_scarlet_floor.png',

  env_rift_obelisk: 'assets/images/env_rift_obelisk.png',
  env_rift_shard: 'assets/images/env_rift_shard.png',
  env_rift_portal: 'assets/images/env_rift_portal.png',
  env_rift_floor: 'assets/images/env_rift_floor.png',

  vfx_emp_pulse: 'assets/images/vfx_emp_pulse.png',
  vfx_ember_explosion: 'assets/images/vfx_ember_explosion.png',
  vfx_void_orb: 'assets/images/vfx_void_orb.png',
  vfx_distortion_beam: 'assets/images/vfx_distortion_beam.png',
  vfx_electric_bolt: 'assets/images/vfx_electric_bolt.png',
  vfx_scarlet_slash: 'assets/images/vfx_scarlet_slash.png',
  vfx_emerald_beam: 'assets/images/vfx_emerald_beam.png',
  vfx_reality_fracture: 'assets/images/vfx_reality_fracture.png',
  vfx_spark_burst: 'assets/images/vfx_spark_burst.png',
  vfx_flame_shot: 'assets/images/vfx_flame_shot.png',
  vfx_leaf_slash: 'assets/images/vfx_leaf_slash.png',
  vfx_root_snare: 'assets/images/vfx_root_snare.png',

  robotic_drone: 'assets/images/robotic_drone.png',
  rift_skitter: 'assets/images/rift_skitter.png',

  jade_stalker_idle: 'assets/images/jade_stalker_idle.png',
  jade_stalker_run: 'assets/images/jade_stalker_run.png',
  jade_stalker_attack: 'assets/images/jade_stalker_attack.png',
  jade_stalker_hurt: 'assets/images/jade_stalker_hurt.png',
  jade_stalker_death: 'assets/images/jade_stalker_death.png',

  rift_lancer_idle: 'assets/images/rift_lancer_idle.png',
  rift_lancer_run: 'assets/images/rift_lancer_run.png',
  rift_lancer_attack: 'assets/images/rift_lancer_attack.png',
  rift_lancer_hurt: 'assets/images/rift_lancer_hurt.png',
  rift_lancer_death: 'assets/images/rift_lancer_death.png',

  jade_warden_idle: 'assets/images/jade_warden_idle.png',
  jade_warden_walk: 'assets/images/jade_warden_walk.png',
  jade_warden_sword_attack: 'assets/images/jade_warden_sword_attack.png',
  jade_warden_attack: 'assets/images/jade_warden_attack.png',
  jade_warden_hurt: 'assets/images/jade_warden_hurt.png',
  jade_warden_death: 'assets/images/jade_warden_death.png',

  robotic_overseer_idle: 'assets/images/robotic_overseer_idle.png',
  robotic_overseer_walk: 'assets/images/robotic_overseer_walk.png',
  robotic_overseer_attack: 'assets/images/robotic_overseer_attack.png',
  robotic_overseer_shoot: 'assets/images/robotic_overseer_shoot.png',
  robotic_overseer_hurt: 'assets/images/robotic_overseer_hurt.png',
  robotic_overseer_death: 'assets/images/robotic_overseer_death.png',

  jade_guardian_idle: 'assets/images/jade_guardian_idle.png',
  jade_guardian_walk: 'assets/images/jade_guardian_walk.png',
  jade_guardian_attack: 'assets/images/jade_guardian_attack.png',
  jade_guardian_hurt: 'assets/images/jade_guardian_hurt.png',
  jade_guardian_death: 'assets/images/jade_guardian_death.png',

  scarlet_duelist_idle: 'assets/images/scarlet_duelist_idle.png',
  scarlet_duelist_run: 'assets/images/scarlet_duelist_run.png',
  scarlet_duelist_sword_attack: 'assets/images/scarlet_duelist_sword_attack.png',
  scarlet_duelist_hurt: 'assets/images/scarlet_duelist_hurt.png',
  scarlet_duelist_death: 'assets/images/scarlet_duelist_death.png',

  rift_monarch_idle: 'assets/images/rift_monarch_idle.png',
  rift_monarch_walk: 'assets/images/rift_monarch_walk.png',
  rift_monarch_attack: 'assets/images/rift_monarch_attack.png',
  rift_monarch_shoot: 'assets/images/rift_monarch_shoot.png',
  rift_monarch_hurt: 'assets/images/rift_monarch_hurt.png',
  rift_monarch_death: 'assets/images/rift_monarch_death.png',

  robotic_trooper_idle: 'assets/images/robotic_trooper_idle.png',
  robotic_trooper_run: 'assets/images/robotic_trooper_run.png',
  robotic_trooper_shoot: 'assets/images/robotic_trooper_shoot.png',
  robotic_trooper_hurt: 'assets/images/robotic_trooper_hurt.png',
  robotic_trooper_death: 'assets/images/robotic_trooper_death.png',

  scarlet_castellan_idle: 'assets/images/scarlet_castellan_idle.png',
  scarlet_castellan_walk: 'assets/images/scarlet_castellan_walk.png',
  scarlet_castellan_sword_attack: 'assets/images/scarlet_castellan_sword_attack.png',
  scarlet_castellan_attack: 'assets/images/scarlet_castellan_attack.png',
  scarlet_castellan_hurt: 'assets/images/scarlet_castellan_hurt.png',
  scarlet_castellan_death: 'assets/images/scarlet_castellan_death.png',

  scarlet_hound_quad_idle: 'assets/images/scarlet_hound_quad_idle.png',
  scarlet_hound_quad_walk: 'assets/images/scarlet_hound_quad_walk.png',
  scarlet_hound_quad_running: 'assets/images/scarlet_hound_quad_running.png',
  scarlet_hound_quad_jump: 'assets/images/scarlet_hound_quad_jump.png',
};

// Simulation Entities
interface PlayerState {
  x: number;
  y: number;
  vx: number;
  vy: number;
  width: number;
  height: number;
  hp: number;
  maxHp: number;
  facing: 'left' | 'right';
  animState: SpriteAnimationState;
  weaponIndex: number;
  attackCooldown: number;
  dashTimer: number;
  dashCooldownTimer: number;
  isDashing: boolean;
  dashVx: number;
  dashVy: number;
  invincibleTimer: number;
  essence: number;
  combo: number;
  comboTimer: number;
}

interface EnemyEntity {
  id: string;
  type: string;
  name: string;
  isBoss: boolean;
  x: number;
  y: number;
  vx: number;
  vy: number;
  width: number;
  height: number;
  hp: number;
  maxHp: number;
  speed: number;
  facing: 'left' | 'right';
  animState: SpriteAnimationState;
  rendererKey: string;
  attackTimer: number;
  attackCooldown: number;
  hurtTimer: number;
  deathTimer: number;
  isDead: boolean;
  staticAssetKey?: string;
  aiState: 'patrol' | 'chase' | 'windup' | 'attack';
  telegraphTimer: number;
  telegraphMax: number;
  telegraphType?: 'circle' | 'line' | 'cone';
  targetX?: number;
  targetY?: number;
}

interface Projectile {
  id: string;
  x: number;
  y: number;
  vx: number;
  vy: number;
  radius: number;
  damage: number;
  fromPlayer: boolean;
  color: string;
  vfxAssetKey?: string;
  type: 'bullet' | 'beam' | 'slash' | 'vortex';
  life: number;
  maxLife: number;
  penetration?: number;
  vortexRadius?: number;
}

interface TelegraphArea {
  id: string;
  type: 'circle' | 'line' | 'fracture';
  x: number;
  y: number;
  targetX?: number;
  targetY?: number;
  radius?: number;
  width?: number;
  length?: number;
  timer: number;
  maxTime: number;
  color: string;
  damage: number;
  sourceId: string;
}

interface Particle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  life: number;
  maxLife: number;
  color: string;
  size: number;
  shape: 'circle' | 'spark' | 'ring' | 'shard';
  assetKey?: string;
}

interface FloatingText {
  id: string;
  text: string;
  x: number;
  y: number;
  color: string;
  size: number;
  life: number;
  maxLife: number;
  vy: number;
}

interface PropEntity {
  id: string;
  assetKey: string;
  x: number;
  y: number;
  width: number;
  height: number;
  aspect: number;
  solid: boolean;
  interactive: boolean;
  hp?: number;
  maxHp?: number;
  glowColor?: string;
  actionType?: 'shrine' | 'terminal' | 'reactor' | 'crystal' | 'portal';
  used?: boolean;
}

interface EssenceDrop {
  id: string;
  x: number;
  y: number;
  type: 'essence' | 'health' | 'upgrade';
  value: number;
  life: number;
}

export default function App() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const stepperRef = useRef<ReturnType<typeof createFixedStepper>>();
  const lastCancelRef = useRef(false);
  const isMobile = useIsMobile();

  // Playground SDK Integration
  const {sdk} = usePlayground();
  const [exitChat] = useRpc<Record<string, unknown>, void>('ExitChat');

  // Preload Assets
  const {assets, isReady: assetsReady} = useAssets(ASSETS_MANIFEST);

  const canvasWidth = getConfig('baseCanvasWidth') as number;
  const canvasHeight = getConfig('baseCanvasHeight') as number;

  if (!stepperRef.current) {
    const stepMs = getConfig('stepMs');
    const maxSubSteps = getConfig('maxSubSteps');
    stepperRef.current = createFixedStepper(stepMs, maxSubSteps);
  }

  // React HUD & UI State
  const [gameState, setGameState] = useState<GameState>({
    status: 'START',
    score: 0,
    level: 1,
    essence: 0,
    biomeIndex: 0,
    currentWeaponName: WEAPONS[0].name,
  });

  const [isGameMenuOpen, setIsGameMenuOpen] = useState(false);
  const [isHowToPlayOpen, setIsHowToPlayOpen] = useState(false);
  const [isMusicMuted, setIsMusicMuted] = useState(false);
  const [isSfxMuted, setIsSfxMuted] = useState(false);

  // Player live stats for HUD
  const [hudHp, setHudHp] = useState(100);
  const [hudMaxHp, setHudMaxHp] = useState(100);
  const [hudDashReady, setHudDashReady] = useState(true);
  const [hudBoss, setHudBoss] = useState<{name: string; hp: number; maxHp: number; active: boolean} | null>(null);
  const [portalReady, setPortalReady] = useState(false);
  const [biomeBanner, setBiomeBanner] = useState<string | null>(null);

  const gameStateRef = useRef(gameState);
  gameStateRef.current = gameState;

  useEffect(() => {
    (window as any).canHandleBackKey = gameState.status !== 'START';
  }, [gameState.status]);

  const inputRef = useInput(canvasRef, true, {
    width: canvasWidth,
    height: canvasHeight,
  });

  // Mobile virtual joystick & button states
  const touchMovementRef = useRef({x: 0, y: 0});
  const touchAttackRef = useRef(false);
  const touchDashRef = useRef(false);
  const touchAimRef = useRef({x: canvasWidth / 2, y: canvasHeight / 2, active: false});

  // Sprite Renderers Registry
  const spriteRenderersRef = useRef<Record<string, SpriteRenderer>>({});

  // Simulation World Bounds & Camera
  const WORLD_WIDTH = 2400;
  const WORLD_HEIGHT = 1800;
  const cameraRef = useRef({x: 0, y: 0, shake: 0});
  const hitStopTimerRef = useRef(0);

  // Simulation State Refs
  const playerRef = useRef<PlayerState>({
    x: WORLD_WIDTH / 2,
    y: WORLD_HEIGHT / 2,
    vx: 0,
    vy: 0,
    width: 64,
    height: 80,
    hp: 100,
    maxHp: 100,
    facing: 'right',
    animState: {currentAction: 'idle', currentFrame: 0, timer: 0},
    weaponIndex: 0,
    attackCooldown: 0,
    dashTimer: 0,
    dashCooldownTimer: 0,
    isDashing: false,
    dashVx: 0,
    dashVy: 0,
    invincibleTimer: 0,
    essence: 0,
    combo: 0,
    comboTimer: 0,
  });

  const enemiesRef = useRef<EnemyEntity[]>([]);
  const projectilesRef = useRef<Projectile[]>([]);
  const telegraphsRef = useRef<TelegraphArea[]>([]);
  const particlesRef = useRef<Particle[]>([]);
  const floatingTextsRef = useRef<FloatingText[]>([]);
  const propsRef = useRef<PropEntity[]>([]);
  const essenceDropsRef = useRef<EssenceDrop[]>([]);
  const dashGhostsRef = useRef<{x: number; y: number; facing: 'left' | 'right'; alpha: number}[]>([]);

  const biomeKillCountRef = useRef(0);
  const bossSpawnedRef = useRef(false);
  const levelTransitionTimerRef = useRef(0);

  // Initialize SpriteRenderers once
  useEffect(() => {
    const renderers: Record<string, SpriteRenderer> = {};

    // Hero / Jade Stalker
    renderers['hero'] = new SpriteRenderer({
      idle: {imageUrl: 'jade_stalker_idle', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 8, loop: true},
      run: {imageUrl: 'jade_stalker_run', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 16, loop: true},
      attack: {imageUrl: 'jade_stalker_attack', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 16, loop: false},
      hurt: {imageUrl: 'jade_stalker_hurt', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 12, loop: false},
      death: {imageUrl: 'jade_stalker_death', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 10, loop: false},
    });

    // Robotic Trooper
    renderers['robotic_trooper'] = new SpriteRenderer({
      idle: {imageUrl: 'robotic_trooper_idle', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 8, loop: true},
      run: {imageUrl: 'robotic_trooper_run', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 16, loop: true},
      attack: {imageUrl: 'robotic_trooper_shoot', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 16, loop: false},
      hurt: {imageUrl: 'robotic_trooper_hurt', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 12, loop: false},
      death: {imageUrl: 'robotic_trooper_death', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 10, loop: false},
    });

    // Robotic Overseer Boss
    renderers['robotic_overseer'] = new SpriteRenderer({
      idle: {imageUrl: 'robotic_overseer_idle', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 8, loop: true},
      walk: {imageUrl: 'robotic_overseer_walk', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 12, loop: true},
      attack: {imageUrl: 'robotic_overseer_attack', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 14, loop: false},
      shoot: {imageUrl: 'robotic_overseer_shoot', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 16, loop: false},
      hurt: {imageUrl: 'robotic_overseer_hurt', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 10, loop: false},
      death: {imageUrl: 'robotic_overseer_death', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 8, loop: false},
    });

    // Jade Guardian
    renderers['jade_guardian'] = new SpriteRenderer({
      idle: {imageUrl: 'jade_guardian_idle', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 8, loop: true},
      walk: {imageUrl: 'jade_guardian_walk', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 10, loop: true},
      attack: {imageUrl: 'jade_guardian_attack', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 14, loop: false},
      hurt: {imageUrl: 'jade_guardian_hurt', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 10, loop: false},
      death: {imageUrl: 'jade_guardian_death', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 8, loop: false},
    });

    // Jade Warden Boss
    renderers['jade_warden'] = new SpriteRenderer({
      idle: {imageUrl: 'jade_warden_idle', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 8, loop: true},
      walk: {imageUrl: 'jade_warden_walk', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 12, loop: true},
      attack: {imageUrl: 'jade_warden_attack', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 16, loop: false},
      sword_attack: {imageUrl: 'jade_warden_sword_attack', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 16, loop: false},
      hurt: {imageUrl: 'jade_warden_hurt', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 10, loop: false},
      death: {imageUrl: 'jade_warden_death', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 8, loop: false},
    });

    // Scarlet Duelist
    renderers['scarlet_duelist'] = new SpriteRenderer({
      idle: {imageUrl: 'scarlet_duelist_idle', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 8, loop: true},
      run: {imageUrl: 'scarlet_duelist_run', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 16, loop: true},
      attack: {imageUrl: 'scarlet_duelist_sword_attack', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 16, loop: false},
      hurt: {imageUrl: 'scarlet_duelist_hurt', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 10, loop: false},
      death: {imageUrl: 'scarlet_duelist_death', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 8, loop: false},
    });

    // Scarlet Hound Quad
    renderers['scarlet_hound'] = new SpriteRenderer({
      idle: {imageUrl: 'scarlet_hound_quad_idle', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 8, loop: true},
      walk: {imageUrl: 'scarlet_hound_quad_walk', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 12, loop: true},
      run: {imageUrl: 'scarlet_hound_quad_running', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 16, loop: true},
      attack: {imageUrl: 'scarlet_hound_quad_jump', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 16, loop: false},
    });

    // Scarlet Castellan Boss
    renderers['scarlet_castellan'] = new SpriteRenderer({
      idle: {imageUrl: 'scarlet_castellan_idle', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 8, loop: true},
      walk: {imageUrl: 'scarlet_castellan_walk', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 12, loop: true},
      attack: {imageUrl: 'scarlet_castellan_attack', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 16, loop: false},
      sword_attack: {imageUrl: 'scarlet_castellan_sword_attack', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 16, loop: false},
      hurt: {imageUrl: 'scarlet_castellan_hurt', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 10, loop: false},
      death: {imageUrl: 'scarlet_castellan_death', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 8, loop: false},
    });

    // Rift Lancer
    renderers['rift_lancer'] = new SpriteRenderer({
      idle: {imageUrl: 'rift_lancer_idle', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 8, loop: true},
      run: {imageUrl: 'rift_lancer_run', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 16, loop: true},
      attack: {imageUrl: 'rift_lancer_attack', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 16, loop: false},
      hurt: {imageUrl: 'rift_lancer_hurt', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 10, loop: false},
      death: {imageUrl: 'rift_lancer_death', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 8, loop: false},
    });

    // Paradox Monarch Boss
    renderers['rift_monarch'] = new SpriteRenderer({
      idle: {imageUrl: 'rift_monarch_idle', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 8, loop: true},
      walk: {imageUrl: 'rift_monarch_walk', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 10, loop: true},
      attack: {imageUrl: 'rift_monarch_attack', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 16, loop: false},
      shoot: {imageUrl: 'rift_monarch_shoot', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 16, loop: false},
      hurt: {imageUrl: 'rift_monarch_hurt', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 10, loop: false},
      death: {imageUrl: 'rift_monarch_death', totalFrames: 16, frameWidth: 512, frameHeight: 512, fps: 8, loop: false},
    });

    spriteRenderersRef.current = renderers;
  }, []);

  // Spawn Biome Props
  const initBiomeEnvironment = useCallback((biomeIdx: number) => {
    const props: PropEntity[] = [];
    const b = BIOMES[biomeIdx];

    if (b.id === 'robotic') {
      props.push(
        {id: 'r1', assetKey: 'env_robot_reactor', x: 500, y: 400, width: 80, height: 116, aspect: 538 / 782, solid: true, interactive: true, hp: 60, maxHp: 60, actionType: 'reactor'},
        {id: 'r2', assetKey: 'env_robot_reactor', x: 1900, y: 400, width: 80, height: 116, aspect: 538 / 782, solid: true, interactive: true, hp: 60, maxHp: 60, actionType: 'reactor'},
        {id: 'r3', assetKey: 'env_robot_reactor', x: 1200, y: 1400, width: 80, height: 116, aspect: 538 / 782, solid: true, interactive: true, hp: 60, maxHp: 60, actionType: 'reactor'},
        {id: 't1', assetKey: 'env_robot_terminal', x: 800, y: 900, width: 70, height: 70, aspect: 1, solid: true, interactive: true, actionType: 'terminal'},
        {id: 't2', assetKey: 'env_robot_terminal', x: 1600, y: 900, width: 70, height: 70, aspect: 1, solid: true, interactive: true, actionType: 'terminal'},
        {id: 'h1', assetKey: 'env_robot_hazard_panel', x: 1200, y: 900, width: 90, height: 63, aspect: 884 / 620, solid: false, interactive: false}
      );
    } else if (b.id === 'jade') {
      props.push(
        {id: 'jp1', assetKey: 'env_jade_pillar', x: 600, y: 500, width: 70, height: 127, aspect: 465 / 844, solid: true, interactive: false},
        {id: 'jp2', assetKey: 'env_jade_pillar', x: 1800, y: 500, width: 70, height: 127, aspect: 465 / 844, solid: true, interactive: false},
        {id: 'jp3', assetKey: 'env_jade_pillar', x: 600, y: 1300, width: 70, height: 127, aspect: 465 / 844, solid: true, interactive: false},
        {id: 'jp4', assetKey: 'env_jade_pillar', x: 1800, y: 1300, width: 70, height: 127, aspect: 465 / 844, solid: true, interactive: false},
        {id: 'jc1', assetKey: 'env_jade_crystal', x: 1200, y: 400, width: 80, height: 102, aspect: 618 / 792, solid: true, interactive: true, hp: 50, maxHp: 50, actionType: 'crystal'},
        {id: 'jc2', assetKey: 'env_jade_crystal', x: 1200, y: 1400, width: 80, height: 102, aspect: 618 / 792, solid: true, interactive: true, hp: 50, maxHp: 50, actionType: 'crystal'},
        {id: 'js1', assetKey: 'env_jade_shrine', x: 1200, y: 900, width: 100, height: 90, aspect: 660 / 598, solid: true, interactive: true, glowColor: '#10b981', actionType: 'shrine'}
      );
    } else if (b.id === 'scarlet') {
      props.push(
        {id: 'sb1', assetKey: 'env_scarlet_brazier', x: 700, y: 450, width: 65, height: 72, aspect: 618 / 690, solid: true, interactive: false},
        {id: 'sb2', assetKey: 'env_scarlet_brazier', x: 1700, y: 450, width: 65, height: 72, aspect: 618 / 690, solid: true, interactive: false},
        {id: 'sb3', assetKey: 'env_scarlet_brazier', x: 700, y: 1350, width: 65, height: 72, aspect: 618 / 690, solid: true, interactive: false},
        {id: 'sb4', assetKey: 'env_scarlet_brazier', x: 1700, y: 1350, width: 65, height: 72, aspect: 618 / 690, solid: true, interactive: false},
        {id: 'sbar1', assetKey: 'env_scarlet_barricade', x: 1000, y: 750, width: 90, height: 83, aspect: 783 / 727, solid: true, interactive: true, hp: 80, maxHp: 80},
        {id: 'sbar2', assetKey: 'env_scarlet_barricade', x: 1400, y: 1050, width: 90, height: 83, aspect: 783 / 727, solid: true, interactive: true, hp: 80, maxHp: 80},
        {id: 'sban1', assetKey: 'env_scarlet_banner', x: 1200, y: 250, width: 50, height: 106, aspect: 424 / 904, solid: false, interactive: false}
      );
    } else if (b.id === 'rift') {
      props.push(
        {id: 'ro1', assetKey: 'env_rift_obelisk', x: 600, y: 600, width: 70, height: 125, aspect: 454 / 812, solid: true, interactive: false},
        {id: 'ro2', assetKey: 'env_rift_obelisk', x: 1800, y: 600, width: 70, height: 125, aspect: 454 / 812, solid: true, interactive: false},
        {id: 'ro3', assetKey: 'env_rift_obelisk', x: 1200, y: 1400, width: 70, height: 125, aspect: 454 / 812, solid: true, interactive: false},
        {id: 'rs1', assetKey: 'env_rift_shard', x: 950, y: 900, width: 70, height: 86, aspect: 566 / 700, solid: true, interactive: true, hp: 60, maxHp: 60, actionType: 'crystal'},
        {id: 'rs2', assetKey: 'env_rift_shard', x: 1450, y: 900, width: 70, height: 86, aspect: 566 / 700, solid: true, interactive: true, hp: 60, maxHp: 60, actionType: 'crystal'}
      );
    }

    propsRef.current = props;
    enemiesRef.current = [];
    projectilesRef.current = [];
    telegraphsRef.current = [];
    essenceDropsRef.current = [];
    biomeKillCountRef.current = 0;
    bossSpawnedRef.current = false;
    setPortalReady(false);
    setHudBoss(null);

    // Trigger Biome Banner
    setBiomeBanner(`${b.name} - ${b.subtitle}`);
    setTimeout(() => setBiomeBanner(null), 3500);
  }, []);

  // Spawn Enemy Function
  const spawnEnemy = useCallback((biomeIdx: number, forceBoss = false) => {
    const b = BIOMES[biomeIdx];
    const player = playerRef.current;

    // Spawn at perimeter outside player's immediate view
    let spawnX = 0;
    let spawnY = 0;
    const angle = Math.random() * Math.PI * 2;
    const dist = forceBoss ? 600 : 450 + Math.random() * 350;
    spawnX = Math.max(100, Math.min(WORLD_WIDTH - 100, player.x + Math.cos(angle) * dist));
    spawnY = Math.max(100, Math.min(WORLD_HEIGHT - 100, player.y + Math.sin(angle) * dist));

    if (forceBoss) {
      bossSpawnedRef.current = true;
      gameAudio.playPowerupChime();
      let bossKey = 'robotic_overseer';
      let bossName = b.bossName;
      let hp = 700 * (getConfig('bossHealthMultiplier') as number);

      if (b.id === 'jade') {
        bossKey = 'jade_warden';
        hp = 850 * (getConfig('bossHealthMultiplier') as number);
      } else if (b.id === 'scarlet') {
        bossKey = 'scarlet_castellan';
        hp = 1000 * (getConfig('bossHealthMultiplier') as number);
      } else if (b.id === 'rift') {
        bossKey = 'rift_monarch';
        hp = 1300 * (getConfig('bossHealthMultiplier') as number);
      }

      const bossEntity: EnemyEntity = {
        id: `boss_${Date.now()}`,
        type: bossKey,
        name: bossName,
        isBoss: true,
        x: spawnX,
        y: spawnY,
        vx: 0,
        vy: 0,
        width: 130,
        height: 150,
        hp,
        maxHp: hp,
        speed: 130,
        facing: 'right',
        animState: {currentAction: 'idle', currentFrame: 0, timer: 0},
        rendererKey: bossKey,
        attackTimer: 0,
        attackCooldown: 2.2,
        hurtTimer: 0,
        deathTimer: 0,
        isDead: false,
        aiState: 'chase',
        telegraphTimer: 0,
        telegraphMax: 1.0,
      };

      enemiesRef.current.push(bossEntity);
      setHudBoss({name: bossName, hp, maxHp: hp, active: true});
      return;
    }

    // Standard Biome Enemies
    const rand = Math.random();
    let enemyType = 'robotic_trooper';
    let rendererKey = 'robotic_trooper';
    let staticAssetKey: string | undefined;
    let width = 64;
    let height = 80;
    let hp = 45;
    let speed = 160;
    let attackCooldown = 1.6;

    if (b.id === 'robotic') {
      if (rand > 0.45) {
        enemyType = 'robotic_drone';
        staticAssetKey = 'robotic_drone';
        width = 54;
        height = 42;
        hp = 30;
        speed = 210;
        attackCooldown = 1.3;
      }
    } else if (b.id === 'jade') {
      if (rand > 0.4) {
        enemyType = 'jade_guardian';
        rendererKey = 'jade_guardian';
        width = 80;
        height = 95;
        hp = 95;
        speed = 110;
        attackCooldown = 2.0;
      } else {
        enemyType = 'jade_stalker';
        rendererKey = 'hero';
        width = 64;
        height = 80;
        hp = 45;
        speed = 220;
        attackCooldown = 1.2;
      }
    } else if (b.id === 'scarlet') {
      if (rand > 0.45) {
        enemyType = 'scarlet_hound';
        rendererKey = 'scarlet_hound';
        width = 80;
        height = 55;
        hp = 50;
        speed = 240;
        attackCooldown = 1.1;
      } else {
        enemyType = 'scarlet_duelist';
        rendererKey = 'scarlet_duelist';
        width = 64;
        height = 80;
        hp = 60;
        speed = 190;
        attackCooldown = 1.4;
      }
    } else if (b.id === 'rift') {
      if (rand > 0.45) {
        enemyType = 'rift_skitter';
        staticAssetKey = 'rift_skitter';
        width = 58;
        height = 54;
        hp = 35;
        speed = 250;
        attackCooldown = 1.0;
      } else {
        enemyType = 'rift_lancer';
        rendererKey = 'rift_lancer';
        width = 64;
        height = 80;
        hp = 70;
        speed = 200;
        attackCooldown = 1.5;
      }
    }

    const enemy: EnemyEntity = {
      id: `enemy_${Date.now()}_${Math.random()}`,
      type: enemyType,
      name: enemyType.replace('_', ' ').toUpperCase(),
      isBoss: false,
      x: spawnX,
      y: spawnY,
      vx: 0,
      vy: 0,
      width,
      height,
      hp,
      maxHp: hp,
      speed,
      facing: 'right',
      animState: {currentAction: 'idle', currentFrame: 0, timer: 0},
      rendererKey,
      staticAssetKey,
      attackTimer: Math.random() * 0.8,
      attackCooldown,
      hurtTimer: 0,
      deathTimer: 0,
      isDead: false,
      aiState: 'chase',
      telegraphTimer: 0,
      telegraphMax: 0.7,
    };

    enemiesRef.current.push(enemy);
  }, []);

  // Initialize Game Run
  const initGame = useCallback(() => {
    const maxHp = getConfig('playerMaxHealth') as number;
    playerRef.current = {
      x: WORLD_WIDTH / 2,
      y: WORLD_HEIGHT / 2,
      vx: 0,
      vy: 0,
      width: 64,
      height: 80,
      hp: maxHp,
      maxHp,
      facing: 'right',
      animState: {currentAction: 'idle', currentFrame: 0, timer: 0},
      weaponIndex: 0,
      attackCooldown: 0,
      dashTimer: 0,
      dashCooldownTimer: 0,
      isDashing: false,
      dashVx: 0,
      dashVy: 0,
      invincibleTimer: 0,
      essence: 0,
      combo: 0,
      comboTimer: 0,
    };

    setHudHp(maxHp);
    setHudMaxHp(maxHp);
    setHudDashReady(true);
    setIsGameMenuOpen(false);
    setIsHowToPlayOpen(false);

    setGameState({
      status: 'PLAYING',
      score: 0,
      level: 1,
      essence: 0,
      biomeIndex: 0,
      currentWeaponName: WEAPONS[0].name,
    });

    initBiomeEnvironment(0);
    gameAudio.playPowerupChime();

    if (sdk) {
      sdk.startGame();
    }
  }, [sdk, initBiomeEnvironment]);

  // Handle advance to next biome
  const advanceBiome = useCallback(() => {
    const nextIdx = gameStateRef.current.biomeIndex + 1;
    if (nextIdx >= BIOMES.length) {
      // Victory!
      setGameState((prev) => ({...prev, status: 'VICTORY', score: prev.score + 5000}));
      gameAudio.playVictoryFanfare();
      return;
    }

    gameAudio.playLevelUpStinger();
    setGameState((prev) => ({
      ...prev,
      biomeIndex: nextIdx,
      level: nextIdx + 1,
      score: prev.score + 1500,
    }));

    // Unlock next weapons
    playerRef.current.weaponIndex = (playerRef.current.weaponIndex + 2) % WEAPONS.length;
    // Heal player 50%
    playerRef.current.hp = Math.min(playerRef.current.maxHp, playerRef.current.hp + playerRef.current.maxHp * 0.5);
    setHudHp(playerRef.current.hp);

    playerRef.current.x = WORLD_WIDTH / 2;
    playerRef.current.y = WORLD_HEIGHT / 2;

    initBiomeEnvironment(nextIdx);
  }, [initBiomeEnvironment]);

  // Hook for reporting lifecycle
  usePlaygroundGameLifecycle(gameState, sdk);

  // Auto-play URL param
  const hasAutoplayed = useRef(false);
  useEffect(() => {
    if (!hasAutoplayed.current && new URLSearchParams(window.location.search).has('autoplay')) {
      hasAutoplayed.current = true;
      initGame();
    }
  }, [initGame]);

  // Weapon Switcher
  const cycleWeapon = (dir: 1 | -1) => {
    const p = playerRef.current;
    p.weaponIndex = (p.weaponIndex + dir + WEAPONS.length) % WEAPONS.length;
    setGameState((prev) => ({
      ...prev,
      currentWeaponName: WEAPONS[p.weaponIndex].name,
    }));
    gameAudio.playCrispClick();

    // Floating notification
    floatingTextsRef.current.push({
      id: `w_${Date.now()}`,
      text: WEAPONS[p.weaponIndex].name,
      x: p.x,
      y: p.y - 45,
      color: WEAPONS[p.weaponIndex].color,
      size: 16,
      life: 0.8,
      maxLife: 0.8,
      vy: -35,
    });
  };

  // Keyboard weapon swap shortcuts & Escape menu
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (gameStateRef.current.status !== 'PLAYING') return;
      if (e.key === 'q' || e.key === 'Q') {
        cycleWeapon(-1);
      } else if (e.key === 'e' || e.key === 'E') {
        cycleWeapon(1);
      } else if (e.key === 'Shift') {
        triggerDash();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  // Dash Trigger
  const triggerDash = () => {
    const p = playerRef.current;
    if (p.dashCooldownTimer > 0 || p.isDashing) return;

    const dashSpeed = getConfig('dashSpeed') as number;
    let dx = p.vx;
    let dy = p.vy;
    if (dx === 0 && dy === 0) {
      dx = p.facing === 'right' ? 1 : -1;
    }
    const len = Math.hypot(dx, dy) || 1;
    p.dashVx = (dx / len) * dashSpeed;
    p.dashVy = (dy / len) * dashSpeed;
    p.dashTimer = 0.22;
    p.dashCooldownTimer = getConfig('dashCooldown') as number;
    p.isDashing = true;
    p.invincibleTimer = 0.3;
    setHudDashReady(false);
    gameAudio.playGunshotBlast();

    // Spawn initial dash sparks
    for (let i = 0; i < 8; i++) {
      particlesRef.current.push({
        x: p.x,
        y: p.y + 10,
        vx: (Math.random() - 0.5) * 150 - p.dashVx * 0.2,
        vy: (Math.random() - 0.5) * 150 - p.dashVy * 0.2,
        life: 0.35,
        maxLife: 0.35,
        color: '#38bdf8',
        size: 5,
        shape: 'spark',
      });
    }
  };

  // Player Attack Trigger
  const triggerPlayerAttack = (aimX: number, aimY: number) => {
    const p = playerRef.current;
    if (p.attackCooldown > 0 || p.isDashing) return;

    const currentWeapon = WEAPONS[p.weaponIndex];
    p.attackCooldown = currentWeapon.cooldown;
    p.animState = {currentAction: 'attack', currentFrame: 0, timer: 0};

    const angle = Math.atan2(aimY - p.y, aimX - p.x);
    p.facing = aimX >= p.x ? 'right' : 'left';

    const baseDmg = (getConfig('playerAttackDamage') as number) + currentWeapon.damage;

    if (currentWeapon.type === 'projectile') {
      if (currentWeapon.id === 'arc_blaster') {
        gameAudio.playArcadeLaser();
        // Twin projectile
        [-0.1, 0.1].forEach((spread) => {
          const a = angle + spread;
          projectilesRef.current.push({
            id: `p_${Date.now()}_${Math.random()}`,
            x: p.x + Math.cos(a) * 20,
            y: p.y + Math.sin(a) * 20,
            vx: Math.cos(a) * currentWeapon.speed,
            vy: Math.sin(a) * currentWeapon.speed,
            radius: 8,
            damage: baseDmg * 0.6,
            fromPlayer: true,
            color: currentWeapon.color,
            vfxAssetKey: currentWeapon.vfxAssetId,
            type: 'bullet',
            life: currentWeapon.range / currentWeapon.speed,
            maxLife: currentWeapon.range / currentWeapon.speed,
          });
        });
      } else if (currentWeapon.id === 'ember_cannon') {
        gameAudio.playGunshotBlast();
        projectilesRef.current.push({
          id: `p_${Date.now()}`,
          x: p.x + Math.cos(angle) * 25,
          y: p.y + Math.sin(angle) * 25,
          vx: Math.cos(angle) * currentWeapon.speed,
          vy: Math.sin(angle) * currentWeapon.speed,
          radius: 14,
          damage: baseDmg,
          fromPlayer: true,
          color: currentWeapon.color,
          vfxAssetKey: 'vfx_flame_shot',
          type: 'bullet',
          life: currentWeapon.range / currentWeapon.speed,
          maxLife: currentWeapon.range / currentWeapon.speed,
        });
      } else {
        // Crystal staff homing
        gameAudio.playArcadeLaser();
        projectilesRef.current.push({
          id: `p_${Date.now()}`,
          x: p.x + Math.cos(angle) * 20,
          y: p.y + Math.sin(angle) * 20,
          vx: Math.cos(angle) * currentWeapon.speed,
          vy: Math.sin(angle) * currentWeapon.speed,
          radius: 9,
          damage: baseDmg,
          fromPlayer: true,
          color: currentWeapon.color,
          vfxAssetKey: currentWeapon.vfxAssetId,
          type: 'bullet',
          life: currentWeapon.range / currentWeapon.speed,
          maxLife: currentWeapon.range / currentWeapon.speed,
        });
      }
    } else if (currentWeapon.type === 'beam') {
      gameAudio.playArcadeLaser();
      projectilesRef.current.push({
        id: `p_${Date.now()}`,
        x: p.x + Math.cos(angle) * 25,
        y: p.y + Math.sin(angle) * 25,
        vx: Math.cos(angle) * currentWeapon.speed,
        vy: Math.sin(angle) * currentWeapon.speed,
        radius: 10,
        damage: baseDmg,
        fromPlayer: true,
        color: currentWeapon.color,
        vfxAssetKey: currentWeapon.vfxAssetId,
        type: 'beam',
        life: currentWeapon.range / currentWeapon.speed,
        maxLife: currentWeapon.range / currentWeapon.speed,
        penetration: 3,
      });
    } else if (currentWeapon.type === 'melee') {
      gameAudio.playSwordClash();
      projectilesRef.current.push({
        id: `p_${Date.now()}`,
        x: p.x + Math.cos(angle) * 45,
        y: p.y + Math.sin(angle) * 45,
        vx: Math.cos(angle) * 120,
        vy: Math.sin(angle) * 120,
        radius: 40,
        damage: baseDmg,
        fromPlayer: true,
        color: currentWeapon.color,
        vfxAssetKey: currentWeapon.vfxAssetId,
        type: 'slash',
        life: 0.18,
        maxLife: 0.18,
        penetration: 99,
      });
    } else if (currentWeapon.type === 'vortex') {
      gameAudio.playPowerupChime();
      projectilesRef.current.push({
        id: `p_${Date.now()}`,
        x: p.x + Math.cos(angle) * 30,
        y: p.y + Math.sin(angle) * 30,
        vx: Math.cos(angle) * currentWeapon.speed,
        vy: Math.sin(angle) * currentWeapon.speed,
        radius: 20,
        damage: baseDmg * 0.4,
        fromPlayer: true,
        color: currentWeapon.color,
        vfxAssetKey: currentWeapon.vfxAssetId,
        type: 'vortex',
        life: 1.5,
        maxLife: 1.5,
        vortexRadius: 180,
      });
    }
  };

  // ----------------------------------------------------
  // UPDATE LOOP (60 FPS FIXED STEPPER)
  // ----------------------------------------------------
  const update = (dt: number) => {
    if (gameStateRef.current.status !== 'PLAYING' || isGameMenuOpen) return;

    if (hitStopTimerRef.current > 0) {
      hitStopTimerRef.current -= dt;
      return;
    }

    const p = playerRef.current;
    const currentBiomeIdx = gameStateRef.current.biomeIndex;
    const biome = BIOMES[currentBiomeIdx];
    const input = inputRef.current;

    // Camera Shake Decay
    if (cameraRef.current.shake > 0) {
      cameraRef.current.shake = Math.max(0, cameraRef.current.shake - dt * 25);
    }

    // Input Movement
    let moveX = 0;
    let moveY = 0;

    if (input.actions.left) moveX -= 1;
    if (input.actions.right) moveX += 1;
    if (input.actions.up) moveY -= 1;
    if (input.actions.down) moveY += 1;

    // Add mobile joystick values
    if (touchMovementRef.current.x !== 0 || touchMovementRef.current.y !== 0) {
      moveX = touchMovementRef.current.x;
      moveY = touchMovementRef.current.y;
    }

    const moveMag = Math.hypot(moveX, moveY);
    const playerSpeed = getConfig('playerSpeed') as number;

    if (!p.isDashing) {
      if (moveMag > 0.05) {
        p.vx = (moveX / (moveMag > 1 ? moveMag : 1)) * playerSpeed;
        p.vy = (moveY / (moveMag > 1 ? moveMag : 1)) * playerSpeed;
        if (moveX > 0) p.facing = 'right';
        else if (moveX < 0) p.facing = 'left';

        if (p.animState.currentAction !== 'run' && p.animState.currentAction !== 'attack') {
          p.animState = {currentAction: 'run', currentFrame: 0, timer: 0};
        }
      } else {
        p.vx = 0;
        p.vy = 0;
        if (p.animState.currentAction !== 'idle' && p.animState.currentAction !== 'attack') {
          p.animState = {currentAction: 'idle', currentFrame: 0, timer: 0};
        }
      }
    }

    // Handle Dash
    if (p.isDashing) {
      p.x += p.dashVx * dt;
      p.y += p.dashVy * dt;
      p.dashTimer -= dt;

      // Spawn afterimage ghost
      if (Math.random() < 0.6) {
        dashGhostsRef.current.push({
          x: p.x,
          y: p.y,
          facing: p.facing,
          alpha: 0.6,
        });
      }

      if (p.dashTimer <= 0) {
        p.isDashing = false;
        p.vx = 0;
        p.vy = 0;
      }
    } else {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
    }

    // World Bounds Clamping
    p.x = Math.max(50, Math.min(WORLD_WIDTH - 50, p.x));
    p.y = Math.max(50, Math.min(WORLD_HEIGHT - 50, p.y));

    // Props Solid Collisions
    propsRef.current.forEach((prop) => {
      if (!prop.solid) return;
      const hw = prop.width / 2;
      const hh = prop.height / 2;
      const dx = p.x - prop.x;
      const dy = p.y - prop.y;
      if (Math.abs(dx) < hw + p.width / 3 && Math.abs(dy) < hh + p.height / 3) {
        if (Math.abs(dx) > Math.abs(dy)) {
          p.x = prop.x + Math.sign(dx) * (hw + p.width / 3);
        } else {
          p.y = prop.y + Math.sign(dy) * (hh + p.height / 3);
        }
      }
    });

    // Dash Cooldown timer
    if (p.dashCooldownTimer > 0) {
      p.dashCooldownTimer -= dt;
      if (p.dashCooldownTimer <= 0) {
        setHudDashReady(true);
      }
    }

    // Attack Cooldown & Invincibility timers
    if (p.attackCooldown > 0) p.attackCooldown -= dt;
    if (p.invincibleTimer > 0) p.invincibleTimer -= dt;

    // Combo Timer Decay
    if (p.combo > 0) {
      p.comboTimer -= dt;
      if (p.comboTimer <= 0) {
        p.combo = 0;
      }
    }

    // Update Player Animation State
    const heroRenderer = spriteRenderersRef.current['hero'];
    if (heroRenderer) {
      p.animState = heroRenderer.getNextState(p.animState, dt);
      if (p.animState.currentAction === 'attack' && p.animState.currentFrame >= 15) {
        p.animState = {currentAction: 'idle', currentFrame: 0, timer: 0};
      }
    }

    // Aim & Shooting Logic
    // Screen to World coords
    const camTargetX = p.x - canvasWidth / 2;
    const camTargetY = p.y - canvasHeight / 2;
    cameraRef.current.x += (camTargetX - cameraRef.current.x) * 0.1;
    cameraRef.current.y += (camTargetY - cameraRef.current.y) * 0.1;

    let worldAimX = p.x + (p.facing === 'right' ? 100 : -100);
    let worldAimY = p.y;

    if (touchAimRef.current.active) {
      worldAimX = touchAimRef.current.x + cameraRef.current.x;
      worldAimY = touchAimRef.current.y + cameraRef.current.y;
    } else if (input.pointer.down || input.actions.confirm || touchAttackRef.current) {
      worldAimX = input.pointer.x + cameraRef.current.x;
      worldAimY = input.pointer.y + cameraRef.current.y;
    }

    if (input.pointer.down || input.actions.confirm || touchAttackRef.current) {
      triggerPlayerAttack(worldAimX, worldAimY);
    }

    // Update Dash Ghosts
    dashGhostsRef.current.forEach((g) => {
      g.alpha -= dt * 3.0;
    });
    dashGhostsRef.current = dashGhostsRef.current.filter((g) => g.alpha > 0);

    // --------------------------------------------------
    // ENEMY SPAWN CONTROLLER
    // --------------------------------------------------
    const spawnMultiplier = (getConfig('enemySpawnRate') as number) || 1.0;
    const maxActiveEnemies = 7 + currentBiomeIdx * 2;
    if (
      enemiesRef.current.length < maxActiveEnemies &&
      biomeKillCountRef.current < biome.requiredKills &&
      !bossSpawnedRef.current
    ) {
      if (Math.random() < 0.03 * spawnMultiplier) {
        spawnEnemy(currentBiomeIdx, false);
      }
    }

    // Spawn Boss when kill threshold met
    if (biomeKillCountRef.current >= biome.requiredKills && !bossSpawnedRef.current) {
      spawnEnemy(currentBiomeIdx, true);
    }

    // --------------------------------------------------
    // UPDATE TELEGRAPHS
    // --------------------------------------------------
    telegraphsRef.current.forEach((t) => {
      t.timer += dt;
      if (t.timer >= t.maxTime) {
        // Execute lethal explosion / damage in telegraph zone
        const dist = Math.hypot(p.x - t.x, p.y - t.y);
        const radius = t.radius || 80;

        if (dist < radius && p.invincibleTimer <= 0) {
          p.hp -= t.damage;
          p.invincibleTimer = 0.5;
          cameraRef.current.shake = 12;
          hitStopTimerRef.current = 0.04;
          gameAudio.playGeneralDamage();
          setHudHp(p.hp);

          floatingTextsRef.current.push({
            id: `dmg_${Date.now()}`,
            text: `-${t.damage}`,
            x: p.x,
            y: p.y - 30,
            color: '#ef4444',
            size: 20,
            life: 0.8,
            maxLife: 0.8,
            vy: -40,
          });

          if (p.hp <= 0) {
            setGameState((prev) => ({...prev, status: 'GAME_OVER'}));
            gameAudio.playDefeatMotif();
          }
        }

        // Spawn VFX on detonation
        for (let i = 0; i < 12; i++) {
          particlesRef.current.push({
            x: t.x,
            y: t.y,
            vx: (Math.random() - 0.5) * 260,
            vy: (Math.random() - 0.5) * 260,
            life: 0.45,
            maxLife: 0.45,
            color: t.color,
            size: 6,
            shape: 'ring',
          });
        }
      }
    });
    telegraphsRef.current = telegraphsRef.current.filter((t) => t.timer < t.maxTime);

    // --------------------------------------------------
    // UPDATE ENEMIES
    // --------------------------------------------------
    enemiesRef.current.forEach((e) => {
      if (e.isDead) {
        e.deathTimer += dt;
        return;
      }

      const distToPlayer = Math.hypot(p.x - e.x, p.y - e.y);
      const angleToPlayer = Math.atan2(p.y - e.y, p.x - e.x);
      e.facing = p.x >= e.x ? 'right' : 'left';

      // Boss Logic vs Regular Enemy Logic
      if (e.isBoss) {
        e.attackTimer += dt;
        if (e.attackTimer >= e.attackCooldown) {
          e.attackTimer = 0;
          // Spawn Boss Telegraph Attacks
          const attackChoice = Math.random();

          if (attackChoice < 0.5) {
            // Giant Impact Ring Telegraph
            telegraphsRef.current.push({
              id: `t_${Date.now()}`,
              type: 'circle',
              x: p.x + (Math.random() - 0.5) * 100,
              y: p.y + (Math.random() - 0.5) * 100,
              radius: 130,
              timer: 0,
              maxTime: 0.9,
              color: biome.primaryColor,
              damage: 28,
              sourceId: e.id,
            });
          } else {
            // Multi-projectile burst / Laser beam
            gameAudio.playArcadeLaser();
            for (let bIdx = -2; bIdx <= 2; bIdx++) {
              const bAngle = angleToPlayer + bIdx * 0.25;
              projectilesRef.current.push({
                id: `bp_${Date.now()}_${bIdx}`,
                x: e.x + Math.cos(bAngle) * 40,
                y: e.y + Math.sin(bAngle) * 40,
                vx: Math.cos(bAngle) * 320,
                vy: Math.sin(bAngle) * 320,
                radius: 12,
                damage: 20,
                fromPlayer: false,
                color: biome.accentColor,
                vfxAssetKey: biome.id === 'rift' ? 'vfx_void_orb' : 'vfx_flame_shot',
                type: 'bullet',
                life: 3.5,
                maxLife: 3.5,
              });
            }
          }
        }

        // Boss Movement towards player with margin
        if (distToPlayer > 180) {
          e.vx = Math.cos(angleToPlayer) * e.speed;
          e.vy = Math.sin(angleToPlayer) * e.speed;
          e.x += e.vx * dt;
          e.y += e.vy * dt;
          if (e.animState.currentAction !== 'walk') {
            e.animState = {currentAction: 'walk', currentFrame: 0, timer: 0};
          }
        } else {
          e.vx = 0;
          e.vy = 0;
          if (e.animState.currentAction !== 'idle') {
            e.animState = {currentAction: 'idle', currentFrame: 0, timer: 0};
          }
        }
      } else {
        // Standard mob movement and attack
        e.attackTimer += dt;
        if (distToPlayer < 240 && e.attackTimer >= e.attackCooldown) {
          e.attackTimer = 0;
          // Mob attack
          if (e.type === 'robotic_drone' || e.type === 'robotic_trooper') {
            gameAudio.playArcadeLaser();
            projectilesRef.current.push({
              id: `ep_${Date.now()}`,
              x: e.x + Math.cos(angleToPlayer) * 20,
              y: e.y + Math.sin(angleToPlayer) * 20,
              vx: Math.cos(angleToPlayer) * 380,
              vy: Math.sin(angleToPlayer) * 380,
              radius: 7,
              damage: 12,
              fromPlayer: false,
              color: '#06b6d4',
              type: 'bullet',
              life: 2.2,
              maxLife: 2.2,
            });
          } else {
            // Melee mob charge telegraph
            telegraphsRef.current.push({
              id: `t_${Date.now()}`,
              type: 'circle',
              x: p.x,
              y: p.y,
              radius: 65,
              timer: 0,
              maxTime: 0.65,
              color: '#ef4444',
              damage: 16,
              sourceId: e.id,
            });
          }
        }

        // Chase player
        if (distToPlayer > 40) {
          e.vx = Math.cos(angleToPlayer) * e.speed;
          e.vy = Math.sin(angleToPlayer) * e.speed;
          e.x += e.vx * dt;
          e.y += e.vy * dt;
          if (e.animState.currentAction !== 'run' && e.animState.currentAction !== 'walk') {
            e.animState = {currentAction: e.rendererKey === 'hero' ? 'run' : 'walk', currentFrame: 0, timer: 0};
          }
        }
      }

      // Update Sprite Animation
      const renderer = spriteRenderersRef.current[e.rendererKey];
      if (renderer) {
        e.animState = renderer.getNextState(e.animState, dt);
      }
    });

    // Filter out finished dead enemies
    enemiesRef.current = enemiesRef.current.filter((e) => !e.isDead || e.deathTimer < 0.6);

    // --------------------------------------------------
    // UPDATE PROJECTILES & COLLISIONS
    // --------------------------------------------------
    projectilesRef.current.forEach((proj) => {
      proj.x += proj.vx * dt;
      proj.y += proj.vy * dt;
      proj.life -= dt;

      // Vortex pull effect
      if (proj.type === 'vortex' && proj.vortexRadius) {
        enemiesRef.current.forEach((e) => {
          if (e.isDead) return;
          const d = Math.hypot(proj.x - e.x, proj.y - e.y);
          if (d < proj.vortexRadius! && d > 10) {
            e.x += ((proj.x - e.x) / d) * 160 * dt;
            e.y += ((proj.y - e.y) / d) * 160 * dt;
          }
        });
      }

      // Player Projectile hitting Enemies
      if (proj.fromPlayer) {
        enemiesRef.current.forEach((enemy) => {
          if (enemy.isDead) return;
          const dist = Math.hypot(proj.x - enemy.x, proj.y - enemy.y);
          const hitThreshold = proj.radius + enemy.width / 2.2;

          if (dist < hitThreshold) {
            enemy.hp -= proj.damage;
            enemy.hurtTimer = 0.2;
            gameAudio.playMeleePunch();

            // Hit Particles
            for (let i = 0; i < 5; i++) {
              particlesRef.current.push({
                x: proj.x,
                y: proj.y,
                vx: (Math.random() - 0.5) * 180,
                vy: (Math.random() - 0.5) * 180,
                life: 0.3,
                maxLife: 0.3,
                color: proj.color,
                size: 4,
                shape: 'spark',
              });
            }

            // Combo counter & damage text
            p.combo += 1;
            p.comboTimer = 2.0;

            floatingTextsRef.current.push({
              id: `ft_${Date.now()}_${Math.random()}`,
              text: `${Math.round(proj.damage)}${p.combo > 3 ? ` (${p.combo}x)` : ''}`,
              x: enemy.x + (Math.random() - 0.5) * 20,
              y: enemy.y - 25,
              color: proj.color,
              size: 16 + Math.min(10, p.combo),
              life: 0.6,
              maxLife: 0.6,
              vy: -30,
            });

            // Boss Health HUD Update
            if (enemy.isBoss) {
              setHudBoss((prev) => (prev ? {...prev, hp: Math.max(0, enemy.hp)} : null));
            }

            // Enemy Death
            if (enemy.hp <= 0) {
              enemy.isDead = true;
              enemy.deathTimer = 0;
              gameAudio.playChiptuneExplosion();

              // Score & Essence
              const pts = enemy.isBoss ? 2000 : 150;
              setGameState((prev) => ({...prev, score: prev.score + pts, essence: prev.essence + (enemy.isBoss ? 50 : 5)}));

              // Drop Essence Orbs
              const dropCount = enemy.isBoss ? 6 : 2;
              for (let k = 0; k < dropCount; k++) {
                essenceDropsRef.current.push({
                  id: `drop_${Date.now()}_${k}`,
                  x: enemy.x + (Math.random() - 0.5) * 40,
                  y: enemy.y + (Math.random() - 0.5) * 40,
                  type: Math.random() < 0.25 ? 'health' : 'essence',
                  value: enemy.isBoss ? 25 : 5,
                  life: 18.0,
                });
              }

              if (enemy.isBoss) {
                // Boss Defeated -> Spawn Portal to next realm
                setPortalReady(true);
                propsRef.current.push({
                  id: 'exit_portal',
                  assetKey: 'env_rift_portal',
                  x: enemy.x,
                  y: enemy.y,
                  width: 110,
                  height: 106,
                  aspect: 782 / 752,
                  solid: false,
                  interactive: true,
                  actionType: 'portal',
                });
                floatingTextsRef.current.push({
                  id: `portal_ann`,
                  text: 'DIMENSIONAL PORTAL OPENED!',
                  x: enemy.x,
                  y: enemy.y - 60,
                  color: '#c084fc',
                  size: 22,
                  life: 3.0,
                  maxLife: 3.0,
                  vy: -15,
                });
                gameAudio.playLevelUpStinger();
              } else {
                biomeKillCountRef.current += 1;
              }
            }

            // Handle penetration or bullet removal
            if (proj.penetration) {
              proj.penetration -= 1;
              if (proj.penetration <= 0) proj.life = 0;
            } else if (proj.type !== 'vortex') {
              proj.life = 0;
            }
          }
        });
      } else {
        // Enemy Projectile hitting Player
        const dist = Math.hypot(proj.x - p.x, proj.y - p.y);
        if (dist < proj.radius + p.width / 3 && p.invincibleTimer <= 0) {
          p.hp -= proj.damage;
          p.invincibleTimer = 0.45;
          cameraRef.current.shake = 8;
          hitStopTimerRef.current = 0.03;
          gameAudio.playGeneralDamage();
          setHudHp(p.hp);
          proj.life = 0;

          floatingTextsRef.current.push({
            id: `dmg_${Date.now()}`,
            text: `-${proj.damage}`,
            x: p.x,
            y: p.y - 30,
            color: '#ef4444',
            size: 18,
            life: 0.7,
            maxLife: 0.7,
            vy: -35,
          });

          if (p.hp <= 0) {
            setGameState((prev) => ({...prev, status: 'GAME_OVER'}));
            gameAudio.playDefeatMotif();
          }
        }
      }
    });

    projectilesRef.current = projectilesRef.current.filter((pr) => pr.life > 0);

    // --------------------------------------------------
    // UPDATE ESSENCE DROPS
    // --------------------------------------------------
    essenceDropsRef.current.forEach((drop) => {
      drop.life -= dt;
      const dist = Math.hypot(p.x - drop.x, p.y - drop.y);
      // Magnet pull towards player
      if (dist < 180) {
        drop.x += ((p.x - drop.x) / dist) * 280 * dt;
        drop.y += ((p.y - drop.y) / dist) * 280 * dt;
      }
      if (dist < 35) {
        drop.life = 0;
        if (drop.type === 'health') {
          p.hp = Math.min(p.maxHp, p.hp + 20);
          setHudHp(p.hp);
          gameAudio.playPowerupChime();
          floatingTextsRef.current.push({
            id: `heal_${Date.now()}`,
            text: '+20 HP',
            x: p.x,
            y: p.y - 35,
            color: '#10b981',
            size: 18,
            life: 0.8,
            maxLife: 0.8,
            vy: -35,
          });
        } else {
          gameAudio.playCoinPickup();
          setGameState((prev) => ({...prev, score: prev.score + 50, essence: prev.essence + drop.value}));
        }
      }
    });
    essenceDropsRef.current = essenceDropsRef.current.filter((d) => d.life > 0);

    // --------------------------------------------------
    // UPDATE INTERACTIVE PROPS & PORTAL
    // --------------------------------------------------
    propsRef.current.forEach((prop) => {
      if (prop.interactive && !prop.used) {
        const dist = Math.hypot(p.x - prop.x, p.y - prop.y);
        if (dist < 70) {
          if (prop.actionType === 'portal') {
            prop.used = true;
            advanceBiome();
          } else if (prop.actionType === 'shrine') {
            prop.used = true;
            p.hp = p.maxHp;
            setHudHp(p.hp);
            gameAudio.playPowerupChime();
            floatingTextsRef.current.push({
              id: `shrine_use`,
              text: 'SACRED BLESSING: FULL HP!',
              x: prop.x,
              y: prop.y - 50,
              color: '#34d399',
              size: 20,
              life: 1.5,
              maxLife: 1.5,
              vy: -25,
            });
          } else if (prop.actionType === 'terminal') {
            prop.used = true;
            setGameState((prev) => ({...prev, score: prev.score + 300, essence: prev.essence + 15}));
            gameAudio.playCoinPickup();
            floatingTextsRef.current.push({
              id: `term_use`,
              text: '+300 DATA ESSENCE',
              x: prop.x,
              y: prop.y - 45,
              color: '#06b6d4',
              size: 18,
              life: 1.2,
              maxLife: 1.2,
              vy: -25,
            });
          }
        }
      }
    });

    // --------------------------------------------------
    // UPDATE PARTICLES & FLOATING TEXTS
    // --------------------------------------------------
    particlesRef.current.forEach((pt) => {
      pt.x += pt.vx * dt;
      pt.y += pt.vy * dt;
      pt.life -= dt;
    });
    particlesRef.current = particlesRef.current.filter((pt) => pt.life > 0);

    floatingTextsRef.current.forEach((ft) => {
      ft.y += ft.vy * dt;
      ft.life -= dt;
    });
    floatingTextsRef.current = floatingTextsRef.current.filter((ft) => ft.life > 0);
  };

  // ----------------------------------------------------
  // DRAW CANVAS FUNCTION (60 FPS)
  // ----------------------------------------------------
  const draw = (ctx: CanvasRenderingContext2D) => {
    prepareCanvas(ctx, canvasWidth, canvasHeight);

    // Calculate Camera Offset with Shake
    const shakeX = (Math.random() - 0.5) * cameraRef.current.shake;
    const shakeY = (Math.random() - 0.5) * cameraRef.current.shake;
    const camX = cameraRef.current.x + shakeX;
    const camY = cameraRef.current.y + shakeY;

    ctx.save();
    // Translate canvas to World View
    ctx.translate(-camX, -camY);

    // 1. Draw Biome Ground Tiling
    const currentBiome = BIOMES[gameStateRef.current.biomeIndex];
    const floorImg = assets[currentBiome.floorAsset];

    const tileSize = 256;
    const startCol = Math.max(0, Math.floor(camX / tileSize));
    const endCol = Math.min(Math.ceil(WORLD_WIDTH / tileSize), Math.ceil((camX + canvasWidth) / tileSize) + 1);
    const startRow = Math.max(0, Math.floor(camY / tileSize));
    const endRow = Math.min(Math.ceil(WORLD_HEIGHT / tileSize), Math.ceil((camY + canvasHeight) / tileSize) + 1);

    for (let c = startCol; c < endCol; c++) {
      for (let r = startRow; r < endRow; r++) {
        const tx = c * tileSize;
        const ty = r * tileSize;
        if (floorImg && floorImg.complete && floorImg.naturalWidth > 0) {
          ctx.drawImage(floorImg, tx, ty, tileSize, tileSize);
        } else {
          ctx.fillStyle = currentBiome.id === 'robotic' ? '#0f172a' : currentBiome.id === 'jade' ? '#064e3b' : currentBiome.id === 'scarlet' ? '#450a0a' : '#2e1065';
          ctx.fillRect(tx, ty, tileSize, tileSize);
          ctx.strokeStyle = '#1e293b';
          ctx.strokeRect(tx, ty, tileSize, tileSize);
        }
      }
    }

    // World Boundary Glow
    ctx.strokeStyle = currentBiome.primaryColor;
    ctx.lineWidth = 6;
    ctx.strokeRect(20, 20, WORLD_WIDTH - 40, WORLD_HEIGHT - 40);

    // 2. Draw Props & Obstacles
    propsRef.current.forEach((prop) => {
      const propImg = assets[prop.assetKey];
      drawAsset(
        ctx,
        propImg,
        prop.x - prop.width / 2,
        prop.y - prop.height / 2,
        prop.width,
        prop.height,
        (fallbackCtx) => {
          fallbackCtx.fillStyle = '#64748b';
          fallbackCtx.fillRect(prop.x - prop.width / 2, prop.y - prop.height / 2, prop.width, prop.height);
        }
      );

      // Draw interactive aura
      if (prop.interactive && !prop.used) {
        ctx.save();
        ctx.strokeStyle = prop.glowColor || currentBiome.primaryColor;
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.arc(prop.x, prop.y, prop.width * 0.7, 0, Math.PI * 2);
        ctx.stroke();
        ctx.restore();
      }
    });

    // 3. Draw Telegraph Projections
    telegraphsRef.current.forEach((t) => {
      ctx.save();
      const progress = Math.min(1, t.timer / t.maxTime);
      const radius = t.radius || 60;

      // Outer telegraph ring
      ctx.strokeStyle = t.color;
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.arc(t.x, t.y, radius, 0, Math.PI * 2);
      ctx.stroke();

      // Filling inner disc
      ctx.fillStyle = `${t.color}44`;
      ctx.beginPath();
      ctx.arc(t.x, t.y, radius * progress, 0, Math.PI * 2);
      ctx.fill();

      // Warning pulse border
      ctx.strokeStyle = '#ffffff';
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.arc(t.x, t.y, radius * progress, 0, Math.PI * 2);
      ctx.stroke();
      ctx.restore();
    });

    // 4. Draw Essence Drops
    essenceDropsRef.current.forEach((drop) => {
      ctx.save();
      ctx.fillStyle = drop.type === 'health' ? '#10b981' : '#f59e0b';
      ctx.shadowColor = ctx.fillStyle;
      ctx.shadowBlur = 10;
      ctx.beginPath();
      ctx.arc(drop.x, drop.y, 7, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    });

    // 5. Draw Dash Ghosts
    dashGhostsRef.current.forEach((ghost) => {
      ctx.save();
      ctx.globalAlpha = ghost.alpha;
      const heroRenderer = spriteRenderersRef.current['hero'];
      if (heroRenderer) {
        heroRenderer.draw(
          ctx,
          {currentAction: 'run', currentFrame: 0, timer: 0},
          ghost.x - 32,
          ghost.y - 40,
          64,
          80,
          assets,
          ghost.facing === 'left'
        );
      }
      ctx.restore();
    });

    // 6. Draw Player Character
    const p = playerRef.current;
    ctx.save();
    if (p.invincibleTimer > 0 && Math.floor(Date.now() / 60) % 2 === 0) {
      ctx.globalAlpha = 0.4;
    }

    const heroRenderer = spriteRenderersRef.current['hero'];
    if (heroRenderer) {
      heroRenderer.draw(
        ctx,
        p.animState,
        p.x - p.width / 2,
        p.y - p.height / 2,
        p.width,
        p.height,
        assets,
        p.facing === 'left'
      );
    }

    // Draw Equipped Weapon over Player
    const currentWeapon = WEAPONS[p.weaponIndex];
    const wpnImg = assets[currentWeapon.assetId];
    if (wpnImg && wpnImg.complete && wpnImg.naturalWidth > 0) {
      ctx.save();
      const wpnOffset = p.facing === 'right' ? 22 : -22;
      ctx.translate(p.x + wpnOffset, p.y);
      if (p.facing === 'left') ctx.scale(-1, 1);
      ctx.drawImage(wpnImg, -18, -18, 36, 36);
      ctx.restore();
    } else {
      ctx.save();
      const wpnOffset = p.facing === 'right' ? 22 : -22;
      ctx.translate(p.x + wpnOffset, p.y);
      ctx.fillStyle = currentWeapon.color;
      ctx.shadowColor = currentWeapon.color;
      ctx.shadowBlur = 6;
      ctx.beginPath();
      ctx.arc(0, 0, 7, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    }
    ctx.restore();

    // 7. Draw Enemies
    enemiesRef.current.forEach((e) => {
      ctx.save();
      if (e.hurtTimer > 0) {
        ctx.filter = 'brightness(1.8) saturate(1.5)';
      }

      if (e.staticAssetKey) {
        const enemyImg = assets[e.staticAssetKey];
        drawAsset(
          ctx,
          enemyImg,
          e.x - e.width / 2,
          e.y - e.height / 2,
          e.width,
          e.height,
          (fallbackCtx) => {
            fallbackCtx.fillStyle = '#ef4444';
            fallbackCtx.fillRect(e.x - e.width / 2, e.y - e.height / 2, e.width, e.height);
          }
        );
      } else {
        const renderer = spriteRenderersRef.current[e.rendererKey];
        if (renderer) {
          renderer.draw(
            ctx,
            e.animState,
            e.x - e.width / 2,
            e.y - e.height / 2,
            e.width,
            e.height,
            assets,
            e.facing === 'left'
          );
        }
      }

      // Draw Mob Health Bar
      if (!e.isBoss && e.hp < e.maxHp) {
        const barW = 40;
        const barH = 5;
        const pct = Math.max(0, e.hp / e.maxHp);
        ctx.fillStyle = 'rgba(0,0,0,0.6)';
        ctx.fillRect(e.x - barW / 2, e.y - e.height / 2 - 10, barW, barH);
        ctx.fillStyle = '#ef4444';
        ctx.fillRect(e.x - barW / 2, e.y - e.height / 2 - 10, barW * pct, barH);
      }
      ctx.restore();
    });

    // 8. Draw Projectiles
    projectilesRef.current.forEach((proj) => {
      ctx.save();
      const vfxImg = proj.vfxAssetKey ? assets[proj.vfxAssetKey] : null;

      if (vfxImg && vfxImg.complete && vfxImg.naturalWidth > 0) {
        ctx.save();
        ctx.translate(proj.x, proj.y);
        const angle = Math.atan2(proj.vy, proj.vx);
        ctx.rotate(angle);
        ctx.drawImage(vfxImg, -proj.radius * 1.5, -proj.radius * 1.5, proj.radius * 3, proj.radius * 3);
        ctx.restore();
      } else {
        ctx.fillStyle = proj.color;
        ctx.shadowColor = proj.color;
        ctx.shadowBlur = 8;
        ctx.beginPath();
        ctx.arc(proj.x, proj.y, Math.max(2, proj.radius), 0, Math.PI * 2);
        ctx.fill();
      }
      ctx.restore();
    });

    // 9. Draw Particles
    particlesRef.current.forEach((pt) => {
      ctx.save();
      ctx.fillStyle = pt.color;
      ctx.globalAlpha = Math.max(0, pt.life / pt.maxLife);
      ctx.beginPath();
      ctx.arc(pt.x, pt.y, Math.max(1, pt.size), 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    });

    // 10. Draw Floating Texts
    floatingTextsRef.current.forEach((ft) => {
      ctx.save();
      ctx.globalAlpha = Math.max(0, ft.life / ft.maxLife);
      ctx.font = `bold ${ft.size}px 'Cinzel', serif, sans-serif`;
      ctx.fillStyle = ft.color;
      ctx.strokeStyle = '#000000';
      ctx.lineWidth = 3;
      ctx.textAlign = 'center';
      ctx.strokeText(ft.text, ft.x, ft.y);
      ctx.fillText(ft.text, ft.x, ft.y);
      ctx.restore();
    });

    ctx.restore(); // End World Translation
  };

  // ----------------------------------------------------
  // RENDER MAIN REACT COMPONENT & OVERLAYS
  // ----------------------------------------------------
  const updateRef = useRef(update);
  const drawRef = useRef(draw);
  updateRef.current = update;
  drawRef.current = draw;

  useEffect(() => {
    let raf = 0;
    const loop = (time: number) => {
      if (inputRef.current) {
        const cancelPressed = inputRef.current.actions.cancel;
        if (cancelPressed && !lastCancelRef.current) {
          if (gameStateRef.current.status === 'PLAYING') {
            setIsGameMenuOpen((prev) => !prev);
          } else if (gameStateRef.current.status === 'START') {
            void exitChat({});
          }
        }
        lastCancelRef.current = cancelPressed;
      }

      stepperRef.current?.(time, (dt) => updateRef.current(dt));

      const ctx = canvasRef.current?.getContext('2d');
      if (ctx) drawRef.current(ctx);

      raf = requestAnimationFrame(loop);
    };

    raf = requestAnimationFrame(loop);
    return () => cancelAnimationFrame(raf);
  }, [exitChat]);

  const isMusicPlaying = gameState.status === 'PLAYING' && !isMusicMuted && !isGameMenuOpen;

  const currentWeapon = WEAPONS[playerRef.current?.weaponIndex || 0];
  const activeBiome = BIOMES[gameState.biomeIndex || 0];

  return (
    <div className="fixed inset-0 overflow-hidden touch-none flex flex-col items-center justify-between bg-slate-950 text-white font-serif select-none">
      <BackgroundMusic url={BACKGROUND_MUSIC_URL} isPlaying={isMusicPlaying} isMuted={isMusicMuted} />

      {/* TOP HUD BAR */}
      <header className="w-full flex items-center justify-between px-3 py-2 bg-slate-900/90 backdrop-blur border-b border-slate-800 z-30 shrink-0 text-xs md:text-sm">
        {/* Left: Player Vital Stats */}
        <div className="flex items-center gap-3">
          {/* Health Bar */}
          <div className="flex items-center gap-1.5">
            <Heart className="w-4 h-4 text-red-500 fill-red-500" />
            <div className="flex flex-col">
              <div className="w-24 md:w-36 h-3 bg-slate-800 rounded-full overflow-hidden border border-slate-700">
                <div
                  className="h-full bg-gradient-to-r from-red-600 to-red-400 transition-all duration-150"
                  style={{width: `${Math.max(0, (hudHp / hudMaxHp) * 100)}%`}}
                />
              </div>
              <span className="text-[10px] text-slate-300 leading-none mt-0.5 font-sans">
                {Math.round(hudHp)} / {hudMaxHp} HP
              </span>
            </div>
          </div>

          {/* Dash Indicator */}
          <div className="flex items-center gap-1">
            <Zap className={`w-3.5 h-3.5 ${hudDashReady ? 'text-cyan-400 animate-pulse' : 'text-slate-600'}`} />
            <span className={`text-[11px] font-bold ${hudDashReady ? 'text-cyan-300' : 'text-slate-500'}`}>
              {hudDashReady ? 'DASH READY' : 'COOLDOWN'}
            </span>
          </div>
        </div>

        {/* Center: Realm & Score */}
        <div className="hidden sm:flex flex-col items-center">
          <div className="text-xs font-bold text-amber-400 tracking-wider">
            {activeBiome?.name}
          </div>
          <div className="flex items-center gap-3 text-[11px] text-slate-400 font-sans">
            <span>Score: <strong className="text-white">{gameState.score}</strong></span>
            <span>Essence: <strong className="text-cyan-300">{gameState.essence}</strong></span>
          </div>
        </div>

        {/* Right: Weapon Info & Menu Button */}
        <div className="flex items-center gap-2">
          {/* Equipped Weapon Badge */}
          <div
            onClick={() => cycleWeapon(1)}
            className="flex items-center gap-1.5 bg-slate-800/80 px-2 py-1 rounded border border-slate-700 cursor-pointer hover:border-cyan-400 transition-colors">
            <Swords className="w-3.5 h-3.5 text-cyan-400" />
            <span className="text-xs font-bold text-cyan-300">{currentWeapon?.name}</span>
            <span className="text-[9px] text-slate-400 ml-1 hidden md:inline font-sans">(Q/E)</span>
          </div>

          {/* Persistent Game Menu Button in Top Right */}
          <button
            onClick={() => setIsGameMenuOpen(true)}
            data-testid="menu-toggle-btn"
            className="p-1.5 md:px-3 md:py-1.5 bg-slate-800 hover:bg-slate-700 text-amber-300 rounded border border-amber-500/40 flex items-center gap-1 transition-colors min-w-[44px] min-h-[44px] justify-center">
            <MenuIcon className="w-4 h-4" />
            <span className="text-xs font-bold hidden md:inline">MENU</span>
          </button>
        </div>
      </header>

      {/* BIOME BANNER NOTIFICATION */}
      {biomeBanner && (
        <div className="absolute top-16 z-20 pointer-events-none flex justify-center w-full animate-bounce">
          <div className="bg-black/85 border-y-2 border-amber-400 px-6 py-2 text-center text-amber-300 text-sm md:text-base font-bold tracking-widest uppercase shadow-2xl">
            {biomeBanner}
          </div>
        </div>
      )}

      {/* BOSS HEALTH BAR OVERLAY */}
      {hudBoss?.active && hudBoss.hp > 0 && (
        <div className="absolute top-14 left-1/2 -translate-x-1/2 z-20 flex flex-col items-center w-11/12 max-w-lg bg-black/80 px-4 py-2 rounded-lg border border-red-500/60 shadow-2xl pointer-events-none">
          <div className="text-xs font-black tracking-wider text-red-400 uppercase flex items-center gap-2 mb-1">
            <Flame className="w-4 h-4 text-orange-500 animate-spin" />
            {hudBoss.name}
            <span className="text-[10px] text-slate-400 font-sans">
              ({Math.round(hudBoss.hp)} / {hudBoss.maxHp})
            </span>
          </div>
          <div className="w-full h-3 bg-slate-900 rounded-full overflow-hidden border border-red-900/80">
            <div
              className="h-full bg-gradient-to-r from-red-600 via-orange-500 to-amber-400 transition-all duration-100"
              style={{width: `${Math.max(0, (hudBoss.hp / hudBoss.maxHp) * 100)}%`}}
            />
          </div>
        </div>
      )}

      {/* MAIN GAME CANVAS CONTAINER */}
      <div className="flex-1 w-full min-h-0 relative flex items-center justify-center bg-slate-950">
        <canvas
          ref={canvasRef}
          width={canvasWidth}
          height={canvasHeight}
          style={{
            aspectRatio: `${canvasWidth} / ${canvasHeight}`,
            width: `min(100%, calc(100vh * ${canvasWidth} / ${canvasHeight}))`,
          }}
          className="h-auto max-w-full max-h-full drop-shadow-2xl"
        />
      </div>

      {/* MOBILE TOUCH CONTROLS */}
      {isMobile && gameState.status === 'PLAYING' && !isGameMenuOpen && (
        <div className="w-full h-28 bg-slate-950/80 backdrop-blur border-t border-slate-800 flex items-center justify-between px-6 z-20 shrink-0 touch-none">
          {/* Virtual D-Pad / Movement */}
          <div className="flex items-center gap-2">
            <div className="grid grid-cols-3 gap-1">
              <div />
              <button
                onPointerDown={() => (touchMovementRef.current.y = -1)}
                onPointerUp={() => (touchMovementRef.current.y = 0)}
                className="w-11 h-11 bg-slate-800/90 active:bg-cyan-600 rounded flex items-center justify-center border border-slate-700 text-lg">
                ▲
              </button>
              <div />
              <button
                onPointerDown={() => (touchMovementRef.current.x = -1)}
                onPointerUp={() => (touchMovementRef.current.x = 0)}
                className="w-11 h-11 bg-slate-800/90 active:bg-cyan-600 rounded flex items-center justify-center border border-slate-700 text-lg">
                ◀
              </button>
              <button
                onPointerDown={() => (touchMovementRef.current.y = 1)}
                onPointerUp={() => (touchMovementRef.current.y = 0)}
                className="w-11 h-11 bg-slate-800/90 active:bg-cyan-600 rounded flex items-center justify-center border border-slate-700 text-lg">
                ▼
              </button>
              <button
                onPointerDown={() => (touchMovementRef.current.x = 1)}
                onPointerUp={() => (touchMovementRef.current.x = 0)}
                className="w-11 h-11 bg-slate-800/90 active:bg-cyan-600 rounded flex items-center justify-center border border-slate-700 text-lg">
                ▶
              </button>
            </div>
          </div>

          {/* Action Buttons Cluster */}
          <div className="flex items-center gap-3">
            {/* Swap Weapon */}
            <button
              onClick={() => cycleWeapon(1)}
              className="w-12 h-12 rounded-full bg-slate-800 border-2 border-amber-400 text-amber-300 flex flex-col items-center justify-center font-bold text-[10px] active:scale-95 transition-transform">
              <Swords className="w-4 h-4" />
              SWAP
            </button>

            {/* Dash */}
            <button
              onClick={triggerDash}
              className={`w-13 h-13 rounded-full flex flex-col items-center justify-center font-bold text-[11px] border-2 transition-transform active:scale-95 ${
                hudDashReady
                  ? 'bg-cyan-900 border-cyan-400 text-cyan-200'
                  : 'bg-slate-800 border-slate-700 text-slate-500'
              }`}>
              <Zap className="w-5 h-5" />
              DASH
            </button>

            {/* Primary Attack */}
            <button
              onPointerDown={() => (touchAttackRef.current = true)}
              onPointerUp={() => (touchAttackRef.current = false)}
              className="w-14 h-14 rounded-full bg-red-800 border-2 border-red-400 text-white flex flex-col items-center justify-center font-bold text-xs active:scale-95 transition-transform shadow-lg shadow-red-900/50">
              <Flame className="w-6 h-6 text-yellow-300" />
              ATTACK
            </button>
          </div>
        </div>
      )}

      {/* START SCREEN OVERLAY */}
      {gameState.status === 'START' && (
        <MenuOverlay tone="neutral">
          <div className="bg-slate-900/95 border-2 border-amber-500/80 p-6 md:p-8 rounded-2xl shadow-2xl flex flex-col items-center w-full max-w-md text-center">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-amber-500/20 text-amber-300 text-xs font-bold mb-3 border border-amber-500/30">
              <Sparkles className="w-3.5 h-3.5" /> 4 FRACTURED REALMS
            </div>
            <h1 className="text-3xl md:text-4xl font-black text-amber-400 tracking-wider mb-2">
              RPG PREMIUM
            </h1>
            <p className="text-sm text-cyan-300 font-semibold mb-6">
              DIMENSIONAL CONQUEROR
            </p>

            <div className="w-full bg-slate-950/80 p-4 rounded-xl border border-slate-800 text-left text-xs text-slate-300 space-y-2 mb-6">
              <div className="flex items-center gap-2 text-amber-400 font-bold">
                <Shield className="w-4 h-4" /> ROGUELITE COMBAT ARSENAL
              </div>
              <p>• 4 Biomes: Robotic Foundry, Jade Temple, Scarlet Fortress, Cosmic Void.</p>
              <p>• 8 Equippable Weapons with dynamic projectile, melee, and vortex VFX.</p>
              <p>• Evade floor warning telegraphs with invulnerable high-speed dashes.</p>
            </div>

            <button
              onClick={initGame}
              autoFocus
              className="w-full bg-gradient-to-r from-amber-500 to-yellow-400 hover:from-amber-400 hover:to-yellow-300 text-slate-950 py-3 rounded-full font-black text-lg tracking-wider transition-all shadow-lg flex items-center justify-center gap-2">
              <Play className="w-5 h-5 fill-current" />
              ENTER THE FRACTURE
            </button>
          </div>
        </MenuOverlay>
      )}

      {/* GAME OVER SCREEN */}
      {gameState.status === 'GAME_OVER' && (
        <Overlay
          title="DEFEAT IN THE FRACTURE"
          description={`Your hero perished. Final Score: ${gameState.score} | Essence: ${gameState.essence}`}
          actionLabel="REAWAKEN"
          onAction={initGame}
          icon={<RotateCw size={24} />}
          tone="danger"
        />
      )}

      {/* VICTORY SCREEN */}
      {gameState.status === 'VICTORY' && (
        <Overlay
          title="PARADOX MONARCH EXTINGUISHED!"
          description={`All 4 fractured realms conquered! Grand Master Score: ${gameState.score}`}
          actionLabel="START NEW ASCENT"
          onAction={initGame}
          icon={<Trophy size={24} />}
          tone="victory"
        />
      )}

      {/* PAUSE / SHARED GAME MENU OVERLAY */}
      {isGameMenuOpen && !isHowToPlayOpen && (
        <MenuOverlay tone="neutral" zIndex={50}>
          <div className="w-full max-w-md bg-slate-900 border-2 border-amber-500/70 rounded-2xl p-6 shadow-2xl flex flex-col items-center">
            <h2 className="text-2xl md:text-3xl font-black text-amber-400 mb-6 tracking-wider">
              GAME MENU
            </h2>

            <div className="w-full flex flex-col gap-3">
              {/* Resume */}
              <button
                onClick={() => setIsGameMenuOpen(false)}
                autoFocus
                className="w-full bg-amber-500 hover:bg-amber-400 text-slate-950 font-bold py-2.5 rounded-lg transition-colors flex items-center justify-center gap-2">
                <Play className="w-4 h-4 fill-current" /> RESUME GAME
              </button>

              {/* Audio Controls Grid */}
              <div className="grid grid-cols-2 gap-3 my-1">
                {/* SFX Toggle */}
                <button
                  onClick={() => {
                    const newMuted = gameAudio.toggleMute();
                    setIsSfxMuted(newMuted);
                  }}
                  className="bg-slate-800 hover:bg-slate-700 border border-slate-700 text-slate-200 py-2 rounded-lg font-bold text-xs flex items-center justify-center gap-2 transition-colors">
                  {isSfxMuted ? <VolumeX className="w-4 h-4 text-red-400" /> : <Volume2 className="w-4 h-4 text-cyan-400" />}
                  SFX: {isSfxMuted ? 'OFF' : 'ON'}
                </button>

                {/* Music Toggle */}
                <button
                  onClick={() => setIsMusicMuted((prev) => !prev)}
                  className="bg-slate-800 hover:bg-slate-700 border border-slate-700 text-slate-200 py-2 rounded-lg font-bold text-xs flex items-center justify-center gap-2 transition-colors">
                  {isMusicMuted ? <VolumeX className="w-4 h-4 text-red-400" /> : <Volume2 className="w-4 h-4 text-amber-400" />}
                  MUSIC: {isMusicMuted ? 'OFF' : 'ON'}
                </button>
              </div>

              {/* How to Play Guide Button */}
              <button
                onClick={() => setIsHowToPlayOpen(true)}
                className="w-full bg-slate-800 hover:bg-slate-700 border border-slate-700 text-cyan-300 font-bold py-2 rounded-lg transition-colors flex items-center justify-center gap-2">
                <Info className="w-4 h-4" /> HOW TO PLAY
              </button>

              {/* Try Biome Again */}
              <button
                onClick={() => {
                  setIsGameMenuOpen(false);
                  initBiomeEnvironment(gameState.biomeIndex || 0);
                  playerRef.current.hp = playerRef.current.maxHp;
                  setHudHp(playerRef.current.hp);
                }}
                className="w-full bg-slate-800 hover:bg-slate-700 border border-slate-700 text-slate-200 font-bold py-2 rounded-lg transition-colors flex items-center justify-center gap-2">
                <RotateCw className="w-4 h-4 text-amber-400" /> RESTART BIOME
              </button>

              {/* Quit to Main Menu */}
              <button
                onClick={() => {
                  setIsGameMenuOpen(false);
                  setGameState((prev) => ({...prev, status: 'START'}));
                }}
                className="w-full bg-red-950/80 hover:bg-red-900 border border-red-800/80 text-red-200 font-bold py-2 rounded-lg transition-colors flex items-center justify-center gap-2 mt-2">
                <X className="w-4 h-4" /> QUIT TO TITLE
              </button>
            </div>
          </div>
        </MenuOverlay>
      )}

      {/* HOW TO PLAY OVERLAY (LAYERED ON TOP) */}
      {isHowToPlayOpen && (
        <MenuOverlay tone="neutral" zIndex={60}>
          <div className="w-full max-w-md bg-slate-900 border-2 border-cyan-500/80 rounded-2xl p-6 shadow-2xl flex flex-col items-center">
            <h2 className="text-xl md:text-2xl font-black text-cyan-300 mb-4 flex items-center gap-2">
              <Info className="w-5 h-5 text-cyan-400" /> COMBAT GUIDE
            </h2>

            <div className="w-full text-xs text-slate-300 space-y-3 mb-6 font-sans">
              <div className="bg-slate-950 p-3 rounded border border-slate-800">
                <strong className="text-amber-300 block mb-1">🎮 CONTROLS:</strong>
                <p>• <strong>W / A / S / D or Arrow Keys:</strong> Omnidirectional movement.</p>
                <p>• <strong>Left Click / Space / Touch Attack:</strong> Aim & Attack.</p>
                <p>• <strong>Right Click / Shift / Touch Dash:</strong> Invulnerable Dash.</p>
                <p>• <strong>Q / E / Swap Button:</strong> Switch equipped weapon archetype.</p>
              </div>

              <div className="bg-slate-950 p-3 rounded border border-slate-800">
                <strong className="text-cyan-300 block mb-1">⚔️ BIOME OVERSEERS:</strong>
                <p>Defeat enemy waves in each realm to summon the Biome Boss. Slay the boss to unlock the portal gateway leading to the next dimension!</p>
              </div>

              <div className="bg-slate-950 p-3 rounded border border-slate-800">
                <strong className="text-red-400 block mb-1">⚠️ TELEGRAPH EVASION:</strong>
                <p>Watch for red and cyan ground markers! Time your dash to dodge lethal boss explosions.</p>
              </div>
            </div>

            <button
              onClick={() => setIsHowToPlayOpen(false)}
              autoFocus
              className="w-full bg-cyan-600 hover:bg-cyan-500 text-white font-bold py-2.5 rounded-lg transition-colors flex items-center justify-center gap-2">
              <ArrowLeft className="w-4 h-4" /> BACK TO MENU
            </button>
          </div>
        </MenuOverlay>
      )}
    </div>
  );
}

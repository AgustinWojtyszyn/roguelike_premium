export interface SpriteActionConfig {
  imageUrl: string;
  totalFrames: number;
  frameWidth: number;
  frameHeight: number;
  fps: number;
  loop?: boolean;
}

export interface SpriteAnimationState {
  currentAction: string;
  currentFrame: number;
  timer: number;
}

export class SpriteRenderer {
  private configs: Record<string, SpriteActionConfig>;

  constructor(configs: Record<string, SpriteActionConfig>) {
    this.configs = configs;
  }

  /**
   * Advances the animation state based on delta time.
   */
  getNextState(
    currentState: SpriteAnimationState,
    deltaTime: number
  ): SpriteAnimationState {
    const config = this.configs[currentState.currentAction];
    if (!config) return currentState;

    const nextState = { ...currentState };
    nextState.timer += deltaTime;
    const frameDuration = 1 / Math.max(1, config.fps);

    if (nextState.timer >= frameDuration) {
      const framesToAdvance = Math.floor(nextState.timer / frameDuration);
      nextState.timer %= frameDuration;
      const nextFrame = (nextState.currentFrame + framesToAdvance);

      if (config.loop === false && nextFrame >= config.totalFrames) {
        nextState.currentFrame = config.totalFrames - 1;
      } else {
        nextState.currentFrame = nextFrame % config.totalFrames;
      }
    }
    return nextState;
  }

  /**
   * Draws the sprite to the canvas using preloaded images.
   */
  draw(
    ctx: CanvasRenderingContext2D,
    state: SpriteAnimationState,
    x: number,
    y: number,
    width: number,
    height: number,
    loadedImages: Record<string, HTMLImageElement | null>,
    flipX = false
  ) {
    const config = this.configs[state.currentAction];
    if (!config) return;

    const img = loadedImages[config.imageUrl];

    if (!img || !img.complete || img.naturalWidth === 0) {
      // High-polish procedural fallback
      ctx.save();
      const isJade = config.imageUrl.includes('jade');
      const isScarlet = config.imageUrl.includes('scarlet');
      const isRift = config.imageUrl.includes('rift');
      const isRobot = config.imageUrl.includes('robotic');
      
      const themeColor = isJade ? '#10b981' : isScarlet ? '#ef4444' : isRift ? '#a855f7' : '#06b6d4';
      ctx.fillStyle = themeColor;
      ctx.shadowColor = themeColor;
      ctx.shadowBlur = 10;
      
      const cx = x + width / 2;
      const cy = y + height / 2;
      const rx = Math.max(4, width * 0.35);
      const ry = Math.max(4, height * 0.45);
      
      ctx.beginPath();
      ctx.ellipse(cx, cy, rx, ry, 0, 0, Math.PI * 2);
      ctx.fill();
      
      ctx.strokeStyle = '#ffffff';
      ctx.lineWidth = 2;
      ctx.stroke();

      // Simple glowing eye / core indicator
      ctx.fillStyle = '#ffffff';
      const eyeOffset = flipX ? -rx * 0.4 : rx * 0.4;
      ctx.beginPath();
      ctx.arc(cx + eyeOffset, cy - ry * 0.3, Math.max(2, rx * 0.25), 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
      return;
    }

    const framesPerRow = Math.max(1, Math.floor(img.width / config.frameWidth));
    const safeFrame = Math.max(0, Math.min(state.currentFrame, config.totalFrames - 1));
    const sourceX = (safeFrame % framesPerRow) * config.frameWidth;
    const sourceY = Math.floor(safeFrame / framesPerRow) * config.frameHeight;

    ctx.save();
    if (flipX) {
      ctx.translate(x + width, y);
      ctx.scale(-1, 1);
      ctx.drawImage(
        img,
        sourceX,
        sourceY,
        config.frameWidth,
        config.frameHeight,
        0,
        0,
        width,
        height
      );
    } else {
      ctx.drawImage(
        img,
        sourceX,
        sourceY,
        config.frameWidth,
        config.frameHeight,
        x,
        y,
        width,
        height
      );
    }
    ctx.restore();
  }
}

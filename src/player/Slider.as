package player
{
  import flash.display.Sprite;
  import flash.display.Stage;
  import flash.events.Event;
  import flash.events.MouseEvent;
  import flash.utils.Timer;
  import flash.events.TimerEvent;

  import vk.VK;

  /**
   * @author Alexey Kharkov
   */
  internal class Slider extends Sprite
  {
    private static const H:uint = 5; // height
    private static const W1:uint = 13; // width (progress slider)
    private static const W2:uint = 7; // width (volume slider)
    private static const MIN_ALPHA:Number = 0.5;
    private static const ALPHA_CHANGE_SPEED:Number = 0.035;
    private static const TIMER_DELAY:uint = 16;
    
    internal var maxX:uint = 0;
    
    private var isVolume:Boolean = false;
    private var w:uint = 0;
    private var dragging:Boolean = false;
    private var timer:Timer = null;
    private var dragX:int = 0;
    private var paused:Boolean = false;

    public function Slider( isVolume:Boolean, parentW:uint ):void
    {
      this.isVolume = isVolume;
      this.w = isVolume ? W2 : W1;
      this.maxX = parentW - w;
      
      this.x = isVolume ? maxX : 0;
      this.y = 0;

      timer = new Timer( TIMER_DELAY, 0 );

      reDraw();
      buttonMode = true;
      
      addEventListener( MouseEvent.MOUSE_DOWN, onDown );
    }
    
    public function set pos( val:Number ):void
    {
      if ( !dragging )
        x = Math.round( maxX * val );
    }
    
    public function get pos():Number
    {
      return Number(x) / maxX;
    }
    
    public function setPaused( b:Boolean ):void
    {
      paused = b;
      startAnim();
    }
    
    // ----------------------------------------------------------------------- Over/Out animation
    private function timerHandler1( e:TimerEvent ):void
    {
      alpha -= ALPHA_CHANGE_SPEED;
      if ( alpha <= MIN_ALPHA )
      {
        alpha = MIN_ALPHA;
        timer.stop();
      }
    }
    
    private function timerHandler2( e:TimerEvent ):void
    {
      alpha += ALPHA_CHANGE_SPEED;
      if ( alpha >= 1.0 )
      {
        alpha = 1.0;
        timer.stop();
      }
    }
    
    private function startAnim():void
    {
      if ( timer.running )
        timer.stop();
      timer = new Timer( TIMER_DELAY, 0 );
      timer.addEventListener( TimerEvent.TIMER, (dragging || paused) ? timerHandler1 : timerHandler2 );
      timer.start();
    }

    // ----------------------------------------------------------------------- Internal methods
    internal function startSlide( stageX:uint ):void
    {
      dragging = true;
      dragX = stageX - x;
      
      if ( !paused )
        startAnim();
        
      Main.STAGE.addEventListener( MouseEvent.MOUSE_UP, onUp );
      Main.STAGE.addEventListener( MouseEvent.MOUSE_MOVE, onMove );
    }
    
    // ----------------------------------------------------------------------- Private methods
    private function reDraw():void
    {
      VK.Utils.fillRect( this, -2, 0, w+4, 8, Main.BG_COLOR, 0.0 );
      VK.Utils.fillRect( this, 0, 0, w, H, LineBase.COL2 );
    }
    
    // ----------------------------------------------------------------------- Event handlers
    private function onDown( e:MouseEvent ):void
    {
      startSlide( e.stageX );
    }

    private function onUp( e:MouseEvent ):void
    {
      if ( dragging )
      {
        dragging = false;
        Main.STAGE.removeEventListener( MouseEvent.MOUSE_UP, onUp );
        Main.STAGE.removeEventListener( MouseEvent.MOUSE_MOVE, onMove );
        
        if ( !paused )
          startAnim();
        
        Object(parent).onSlider();
      }
    }

    private function onMove( e:MouseEvent ):void
    {
      if ( dragging )
      {
        x = e.stageX - dragX;
        x = Math.min( Object(parent).maxX, Math.max( 0, x ) );
        
        if ( isVolume )
          Object(parent).onSlider();
      }
    }
    
  }
}
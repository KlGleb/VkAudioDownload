package gui
{
  import flash.display.Sprite;
  import flash.events.MouseEvent;
  import flash.events.Event;
  import flash.text.TextFieldType;

  import locale.Loc;
  import vk.VK;
  import player.AudioPlayer;

  /**
   * @author Alexey Kharkov
   */
  public class EditAudio extends Sprite
  {
    public static const W:uint = 420;
    private static const X:uint = 110;
    private static const Y:uint = 12;

    private var cur:AudioPlayer = null;
    
    private var par:PlayersContainer = null;
    
    private var tf3:* = null;
    private var but_lyrics:* = null;
    private var cb_no_search:* = null; // CheckBox
    
    private var txt_artist:* = null; // InputField
    private var txt_title:* = null; // InputField
    private var txt_lyrics:* = null; // InputField
    
    public function EditAudio( par:PlayersContainer ):void
    {
      this.par = par;
      
      VK.Utils.fillRect( this, 0, 0, W, 55, 0xffffff );
      
      var tf1:* = VK.addText( Loc.cur.artist + ":", 0, Y, 0x555555 );
      var tf2:* = VK.addText( Loc.cur.title + ":", 0, Y + 27, 0x555555 );
      tf1.x = X - tf1.width - 5;
      tf2.x = X - tf2.width - 5;
      addChild( tf1 );
      addChild( tf2 );
      
      // InputFields width
      var ifw:uint = W - X - Y;

      txt_artist = VK.createInputField( X, tf1.y - 2, ifw );
      addChild( txt_artist );
      
      txt_title  = VK.createInputField( X, tf2.y - 2, ifw );
      addChild( txt_title );
      
      but_lyrics = VK.createLinkButton( Loc.cur.optional, 0, Y + 50, 10 );
      but_lyrics.x = txt_title.x + txt_title.width - but_lyrics.width;
      addChild( but_lyrics );
      but_lyrics.addEventListener( MouseEvent.CLICK, onOpenLyrics );

      tf3 = VK.addText( Loc.cur.lyrics + ":", 0, Y + 54, 0x555555 );
      tf3.x = X - tf3.width - 5;
      tf3.visible = false;
      addChild( tf3 );
      
      txt_lyrics = VK.createInputField( X, tf3.y - 2, ifw, 16 );
      txt_lyrics.visible = false;
      addChild( txt_lyrics );
      
      cb_no_search = VK.createCheckBox( Loc.cur.no_search, X, txt_lyrics.y + txt_lyrics.height + 8 );
      cb_no_search.visible = false;
      addChild( cb_no_search );
    }

    public function reset( p:AudioPlayer, editMode:Boolean ):void
    {
      this.cur = p;
      
      tf3.visible = !editMode;
      txt_lyrics.visible = !editMode;
      
      cb_no_search.visible = false;
      cb_no_search.checked = false;
      
      txt_title .textField.type = editMode ? TextFieldType.INPUT : TextFieldType.DYNAMIC;
      txt_artist.textField.type = editMode ? TextFieldType.INPUT : TextFieldType.DYNAMIC;
      txt_lyrics.textField.type = editMode ? TextFieldType.INPUT : TextFieldType.DYNAMIC;

      txt_title.value = cur.title;
      txt_artist.value = cur.artist;
      txt_lyrics.value = cur.lyrics || "";
    }

    public override function get height():Number
    {
      return Y + (txt_lyrics.visible ? (cb_no_search.visible ? 294 : 278) : 74);
    }

    public function setLyricsId( lyrics_id:uint ):void
    {
      cur.lyrics_id = lyrics_id;
    }
    
    public function updCur():AudioPlayer
    {
       cur.title = txt_title.value;
       cur.artist = txt_artist.value;
       cur.lyrics = txt_lyrics.value;
       return cur;
    }
    
    public function set lyrics( s:String ):void
    {
      txt_lyrics.value = s;
      cur.lyrics = s;
    }
    
    public function get lyrics():String
    {
      return txt_lyrics.value;
    }
    
    public function get no_search():Boolean
    {
      return cb_no_search.checked;
    }
    
    public function getCur():AudioPlayer
    {
      return cur;
    }
    
    // -------------------------------------------------------------------------- Event handlers
    private function onOpenLyrics( e:MouseEvent ):void
    {
      tf3.visible = true;
      txt_lyrics.visible = true;
      cb_no_search.visible = true;
      
      par.reCreateEditBox( cur );
    }
  }
}
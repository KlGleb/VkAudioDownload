package 
{
  import flash.display.DisplayObject;
  import flash.display.Sprite;
  import flash.display.Stage;
  import flash.display.LoaderInfo;
  import flash.events.Event;
  import flash.events.MouseEvent;
  import flash.events.ContextMenuEvent;
  import flash.text.TextField;
  import flash.ui.ContextMenu;
  import flash.ui.ContextMenuItem;
  import flash.system.Security;
  import flash.net.URLRequest;
  import flash.net.navigateToURL;

  import vk.*;
  import gui.*;
  import locale.Loc;

  /**
   * @author Alexey Kharkov
   */
  public class Main extends Sprite
  {
    private static const VER:String = "0.2";
	
	//For local testing please change there:
    private static const MY_ID:uint = 169003; // Please change this to your ID
    private static const MY_APP_ID:uint = 2754884; // Please change this to your APP_ID
    private static const MY_SECRET:String = "af51a171f3"; // Please change this to your secret (flashvars parameter)
    private static const MY_SID:String = "2184ce12f7ca267d3ffba9ea3baf0f23578dcfa64458b72a82952946c80f18"; // Please change this to your sid (flashvars parameter) 
	
    internal static const TEST_MODE:Boolean = false; 
    
	
    private static const MIN_HEIGHT:uint = 50;
    
    public static var wrapper:* = null;
    public static var STAGE:* = null;
    public static const WIDTH:uint = 627; // Best looks with  WIDTH >= 350
    public static const BG_COLOR:uint = 0xffffff;
    public static const HEADER_H:uint = 33;
    public static const PLAYPAUSE_IMG_SCALE:Number = 0.615385;

    // Flash Vars 
    private var vars:Object = null;
    private var user_id:uint = 0;
    private var viewer_id:uint = 0;
    
    // VK API Manager
    public var vkApi:VkApi = null;

    // Menu
    private var menu:* = null;
    internal static var img:PlayPauseImg = null;

    // "Current" variables
    private var cur_full_loc:String = null;
    private var cur_loc:String = null;
    private var cur_search_string:String = "";
    private var curH:uint = 0;

    // Other helper variables
    private var onlyWithLyrics:Boolean = false;
    private var autoStart:Boolean = false;
    private var newAudio:NewAudio = null;
    private var uploadURL:String = null;
    private var justLoaded:Boolean = false;
    private var forceRedraw:Boolean = false;
    private var loadedBar:Sprite = null;
    
    // Header elements
    private var tf_count:TextField = null;
    private var sep:Sprite = null; // Vertical separator
    private var searchInputField:* = null;

    // Players Containers
    private var players_my:PlayersContainer = null;
    private var players_user:PlayersContainer = null;
    private var players_search:PlayersContainer = null;
    private var cur_players:PlayersContainer = null; // Just a reference to a Players Container
    
    // Caching Containers
    private var cont_my:CacheCont = null;
    private var cont_user:CacheCont = null;
    private var cont_search:CacheCont = null;
    public var cur_cont:CacheCont = null; // Just a reference to a Caching Container
    
    // ----------------------------------------------------------------------- Constructor
    public function Main():void 
    {
      //Dbg.log( "START" );
      if ( stage ) init();
      else addEventListener( Event.ADDED_TO_STAGE, init );
    }
    
    // ----------------------------------------------------------------------- Initial methods
    private function init( e:Event = null ):void 
    {
      //Dbg.log( "init()" );
      removeEventListener( Event.ADDED_TO_STAGE, init );
      
      wrapper = Object(parent.parent);
      if ( wrapper.external == null )
        wrapper = stage; // Local
      
      if ( wrapper is Stage )
      {
        STAGE = wrapper;
        vars = LoaderInfo(parent.loaderInfo).parameters;
      }
      else
      {
        STAGE = wrapper.parent;
        vars = wrapper.application.parameters;
        
        wrapper.addEventListener( 'onLocationChanged', onLocationChanged );
        wrapper.addEventListener( 'onSettingsChanged', onSettingsChanged );
      }

      createContextMenu();
      
      // Read FlashVars
      var app_id:uint = getFlashVarInt( "api_id" );
      user_id   = getFlashVarInt( "user_id" );
      viewer_id = getFlashVarInt( "viewer_id" );
      var api_url:String = vars['api_url'];
      var api_res:String = vars['api_result'];
      var sid:String = vars['sid'];
      var secret:String = vars['secret'];
      
      if ( viewer_id == 0 ) // Local testing
      {
        viewer_id = MY_ID;
        user_id = MY_ID;
        app_id = MY_APP_ID;		
		secret = MY_SECRET;
		sid = MY_SID;
        api_url = "http://api.vkontakte.ru/api.php";
      }
      
      if ( user_id == 0 )
        user_id = viewer_id;
        
      // Create VK API manager
      vkApi = new VkApi( this, api_url, viewer_id, app_id, secret, sid );
      
      // Get location strings
      if ( api_res  &&  api_res.indexOf( "\"error\"" ) == -1 )
      {
        vkApi.parseLocStr( api_res );
      } else
        vkApi.getLocValues();
    }
    
    public function onLocValues( obj:* ):void
    {
      //Dbg.log( "onLocValues()" );
      Loc.initLoc( obj );
     
      //
      Security.allowDomain( "*" );
      VK.init( this, "http://api.vkontakte.ru/swf/vk_gui-0.5.swf" );
    }
    
    public function onVKLoaded():void
    {
      //Dbg.log( "onVKLoaded(), cur_full_loc " + cur_full_loc );
      
      // Create MainMenu
      menu = VK.createMainMenu( wrapper, true );
      menu.addItem( Loc.cur.myAudio, "my", false );
      menu.addItem( Loc.cur.userAudio, "user" ).visible = (user_id != viewer_id);
      menu.addItem( Loc.cur.search, "search" );
      menu.addItem( Loc.cur.newAudio, "new" );
      menu.addEventListener( Event.CHANGE, onMenu );
      addChild( menu );
      
      // Create "Play-Pause" image on the main menu
      img = new PlayPauseImg();
      img.buttonMode = true;
      img.x = WIDTH - 21;
      img.y = 16;
      img.scaleX = PLAYPAUSE_IMG_SCALE;
      img.scaleY = PLAYPAUSE_IMG_SCALE;
      img.gotoAndStop( 1 );
      img.visible = false;
      img.addEventListener( MouseEvent.CLICK, PlayersContainer.onImg );
      addChild( img );

      // Create Players Containers
      players_my = new PlayersContainer( this );
      players_user = new PlayersContainer( this );
      players_search = new PlayersContainer( this );

      // Init DebugTracer
      //Dbg.init( STAGE );
      
      // Some GUI elements
      sep = new Sprite();
      VK.Utils.vertSeparator( sep, 0, 0 );
      
      loadedBar = new Sprite();
      VK.Utils.rect( loadedBar, 0, 0, PlayersContainer.PLAYERS_W - 1, 30, 0xf9f6e7, 0xd4bc4c );
      loadedBar.x = 8;
      loadedBar.y = 42;
      loadedBar.addChild( VK.addText( Loc.cur.audioLoaded + ".", 10, 6, 0, VK.Utils.TXT_BOLD ) );

      // Load the default location
      if ( cur_full_loc )
        onLocationChanged( {location:cur_full_loc} );
      else
      if ( wrapper is Stage )
        onLocationChanged( { location:"my" } );
    }
    
    // ----------------------------------------------------------------------- Public methods
    public function goToPage( page:uint, autoStart:Boolean = false ):void
    {
      cur_cont.curPage = page;
      goTo( cur_loc + "/" + cur_cont.curPage + "/" + (autoStart ? 1 : 0) );
    }
    
    public function search( s:String ):void
    {
      cont_search = null;
      goTo( "search/" + s );
    }
    
    public function updateHeight( h:uint ):void
    {
      if ( h > curH )
        setH( h );
    }
    
    public function reset():void
    {
      cont_my = null;
    }

    // ----------------------------------------------------------------------- VkApi callbacks
    public function enGui( b:Boolean ):void
    {
      mouseChildren = b;
    }
    
    public function onUserName( name:String ):void
    {
      menu.selectedItem.label = Loc.cur.audioU + " " + name.substr( 0, 25 );
    }
    
    public function onAudioList( totalCount:uint, arr:Array ):void
    {
      if ( totalCount == 0 )
      {
        enGui( true );
        clearLayout( menu.selectedItem.panel );
        
        var search:Boolean = (menu.selectedPage == 2);
        initMsgRect( menu.selectedItem.panel.addChild( new MsgRect( menu.selectedPage + 2, search ? 63 : 34 ) ) );
        
        var s:String = (cur_search_string == "") 
          ? Loc.cur.enterSearchStr + "." 
          : Loc.cur.noAudio2 + ".";
        
        tf_count = VK.addText( s, PlayersContainer.MARGINS, 12, 0x45688e, VK.Utils.TXT_BOLD );
        menu.selectedItem.panel.addChild( tf_count );
        
        addSearchInputField();
        setH( search ? 260 : 230 );
        return;
      }
      
      // Create and init "Caching Container"
      if ( cur_cont == null  ||  cur_cont.length != totalCount )
        createCurCont( totalCount );
        
      var offset:uint = cur_cont.loadFrom;
      
      cur_cont.addElems( arr, offset );
      cur_cont.markElemsAsLoaded( offset, arr.length, totalCount );
      
      //
      goTo( cur_full_loc );
    }
    
    public function onLyrics( id:uint, s:String ):void
    {
      enGui( true );
      cur_players.onLyrics( s );
    }
    
    public function onUploadServer( url:String ):void
    {
      uploadURL = url;
      goTo( cur_full_loc );
    }
    
    public function onSaved( aid:uint, owner_id:uint, artist:String, title:String, duration:uint, url:String ):void
    {
      reset(); // TODO: avoid re-loading
      justLoaded = true;
      forceRedraw = true;
      goTo( "my" );
    }
    
    public function onRestored( aid:uint, owner_id:uint, artist:String, title:String, duration:uint, url:String ):void
    {
      reset(); // TODO: avoid re-loading
      goTo( "my" );
    }
    
    public function onEdited( lyrics_id:uint ):void
    {
      cur_players.onLyricsId( lyrics_id );
      enGui( true );
    }
    
    public function noPermission():void
    {
      enGui( true );
      setH( 230 );
      initMsgRect( menu.selectedItem.panel.addChild( new MsgRect( 1, 0 ) ) );
    }
    
    public function unkErr():void
    {
      enGui( true );
    }
    
    // ----------------------------------------------------------------------- Common private methods
    private function goTo( loc:String ):void
    {
      //Dbg.log( "goTo( " + loc + " )" );
      enGui( false ); // disable GUI interaction
      
      if ( !(wrapper is Stage)  &&  cur_full_loc != loc )
        wrapper.external.setLocation( loc, true );
      else
        onLocationChanged( {location:loc} );
    }

    private function onLocationChanged( e:* ):void
    {
      //Dbg.log( "onLocationChanged( " + e.location + " ),   cur_full_loc " + cur_full_loc );
      cur_full_loc = e.location;
      
      var def:String = "my"; //(user_id > 0  &&  user_id != viewer_id) ? "user" : "my";
      if ( cur_full_loc.length == 0 )
        cur_full_loc = def;

      enGui( false ); // disable GUI interaction
      
      var arr:Array = cur_full_loc.split( "/" );
      
      var mnu_item:String = arr[0] || def;
      var usr_idx :int = (arr.length > 1) ? parseInt(arr[1]) : 0;
      var page_idx:int = (arr.length > 2) ? parseInt(arr[2]) : -1;
      var s:String = arr[1] || "";
      autoStart = (arr[3] == "1");
      
      cur_loc = mnu_item + "/";
      
      if ( menu == null )
        return;

      menu.setLocation( mnu_item );

      switch ( mnu_item )
      {
      case "user":
        if ( usr_idx == 0 ) usr_idx = user_id;
        cur_loc += usr_idx;
        cur_cont = cont_user;
        cur_players = players_user;
        loadAndShow( usr_idx, page_idx );
        break;
        
      case "search":
        if ( s == "" ) s = cur_search_string;
        cur_loc += s;
        cur_cont = cont_search;
        cur_players = players_search;
        loadAndShow( 0, page_idx, s );
        break;
        
      case "new":
        if ( uploadURL == null )
        {
          vkApi.getUploadServer();
          return;
        }
        if ( newAudio == null )
        {
          newAudio = new NewAudio( uploadURL );
          menu.selectedItem.panel.addChild( newAudio );
          newAudio.addEventListener( NewAudio.EVENT_UPLOADED, onUploaded );
          newAudio.addEventListener( NewAudio.EVENT_SEARCH, onSearch );
        }
        setH( menu.selectedItem.panel.y + newAudio.height );
        enGui( true );
        break;
        
      //case "my":
      default:
        if ( usr_idx == 0 ) usr_idx = viewer_id;
        cur_loc += usr_idx;
        cur_cont = cont_my;
        cur_players = players_my;
        loadAndShow( usr_idx, page_idx );
        break;
      }
    }
    
    private function loadAndShow( usr_idx:uint, page_idx:int, s:String = "" ):void
    {
      //Dbg.log( "loadAndShow( page_idx " + page_idx + " ),  cur_cont " + cur_cont );
      
      if ( cur_cont != null  &&  (usr_idx > 0  ||  s == cur_search_string) )
      {
        if ( page_idx >= 0 )
          cur_cont.curPage = page_idx;
        
        if ( cur_cont.curPageLoaded() )
        {
          // Current page is already loaded, just show it
          showPlayers();
          return;
        }
      }
      
      // Load current page (and some near pages)
      var offset:uint = (cur_cont == null) ? 0 : cur_cont.loadFrom;

      if ( usr_idx > 0 )
        vkApi.getAudio( usr_idx, (usr_idx != viewer_id) );
      else
      {
        cur_search_string = s;
        if ( s.length > 0 )
          vkApi.searchAudio( s, offset, onlyWithLyrics );
        else
          onAudioList( 0, [] );
      }
    }
    
    private function addSearchInputField():void
    {
      if ( menu.selectedLocation == "search" )
      {
        var sp:Sprite = menu.selectedItem.panel;
        
        searchInputField = VK.createInputField( 8, 42, 350 );
        sp.addChild( searchInputField );
        searchInputField.value = cur_search_string;
        searchInputField.addEventListener( VK.InputField.EVENT_MODIFIED, onSearch );

        var but:* = VK.createRoundButton( Loc.cur.search, searchInputField.x + searchInputField.width + 7, searchInputField.y - 1 );
        sp.addChild( but );
        but.addEventListener( MouseEvent.CLICK, onSearch );// function(e:Event):void { onNewSearchString(null); } );
        
        var cb:* = VK.createCheckBox( Loc.cur.withLyrics, 0, searchInputField.y + 4 );
        cb.x = WIDTH - 8 - cb.width;
        sp.addChild( cb );
        cb.checked = onlyWithLyrics;
        cb.addEventListener( MouseEvent.CLICK, function(e:Event):void { onlyWithLyrics = e.target.checked; onSearch(null); } );
        
        searchInputField.setFocus();
      }
    }
    
    private function showPlayers():void
    {
      if ( (forceRedraw  &&  menu.selectedLocation == "my") ||  menu.selectedItem.panel.numChildren == 0  ||  cur_players.needToRedraw )
      {
        var startY:uint = justLoaded ? 39 : 0;

        var own   :Boolean = (menu.selectedPage == 0);
        var search:Boolean = (menu.selectedPage == 2);
        
        clearLayout( menu.selectedItem.panel );
        
        createHeader();
        addSearchInputField();

        cur_players.showPlayers( own, search, startY, autoStart );
        menu.selectedItem.panel.addChild( cur_players );
      }
      
      setH( cur_players.pagH + HEADER_H + ((cur_cont.length > PlayersContainer.ELEMS_ON_PAGE) ? HEADER_H : 0) );

      if ( menu.selectedLocation == "my" )
      {
        // Show "Audio is successfully loaded"
        if ( justLoaded )
          menu.selectedItem.panel.addChild( loadedBar );
        forceRedraw = justLoaded;
        justLoaded = false;
      }
      
      enGui( true ); // GUI is recreated, so we can enable GUI interaction
    }
    
    private function createHeader():void
    {
      var sp:Sprite = menu.selectedItem.panel;
      var xx:uint = PlayersContainer.MARGINS;
      var yy:uint = 12;
      
      var own:Boolean = (menu.selectedPage == 0);
      
      var i1:uint = cur_cont.curIdx + 1;
      var i2:uint = Math.min( cur_cont.length, cur_cont.curIdx + PlayersContainer.ELEMS_ON_PAGE );
      
      var s:String = Loc.audioCountStr( cur_cont.length, i1, i2 );
      if ( !own )
        s += ".";
      
      tf_count = VK.addText( s, xx, yy, 0x45688e, VK.Utils.TXT_BOLD );
      sp.addChild( tf_count );
      xx += tf_count.width + 7;
      
      if ( menu.selectedLocation == "my" )
      {
        sep.x = xx - 5;
        sep.y = yy + 4;
        sp.addChild( sep );
        
        var but_edit:* = VK.createLinkButton( cur_players.editMode ? "Прослушивание аудиозаписей" : "Редактирование", xx, yy );
        sp.addChild( but_edit );
        but_edit.addEventListener( MouseEvent.CLICK, onButEdit );
        xx += but_edit.width + 6;
      }
    }
    
    private function setH( h:int ):void
    {
      //Dbg.log( "setH( " + h + " ),   cur_cont " + cur_cont );
      
      if ( h < MIN_HEIGHT )
        h = MIN_HEIGHT;
      curH = h;
      
      var sp:Sprite = menu.selectedItem.panel;
      sp.graphics.clear();
      
      var search:Boolean = (menu.selectedPage == 2);
      var isPagination:Boolean = (cur_cont != null  &&  cur_cont.length > PlayersContainer.ELEMS_ON_PAGE);
      
      var y1:uint = HEADER_H;
      var y2:uint = cur_players ? cur_players.pagH - 3 : 150;
      var y3:uint = y2 + (isPagination ? HEADER_H : 0);
      var y4:uint = h - sp.y;
      
      VK.Utils.fillRect( sp, 0, 0, WIDTH, y4, 0xf7f7f7 ); // Global gray background
      VK.Utils.fillRect( sp, 0, y1, WIDTH, y2 - y1, 0xf7f7f7 ); // Gray background for AudioPlayers
      if ( cur_players != null  &&  !cur_players.editMode )
      {
        var y5:uint = y1 + 9 + (search ? 30 : 0) + ((justLoaded  &&  menu.selectedLocation == "my") ? 39 : 0);
        VK.Utils.rect( sp, 8, y5, WIDTH - 17, y2 - y5 - 9, BG_COLOR, 0xDAE2E8 ); // In "not-edit mode" we have also a white rect - background for AudioPlayers
      }
      
      VK.Utils.rect( sp, -1, 0, WIDTH + 2, y1, 0xffffff, VK.Utils.BORDER_COL ); // White fields for UP pagination
      if ( isPagination )
        VK.Utils.rect( sp, -1, y2, WIDTH + 2, y3 - y2 - 1, 0xffffff, VK.Utils.BORDER_COL ); // White fields for DOWN pagination
      
      if ( !(wrapper is Stage) )
      {
        wrapper.external.resizeWindow( WIDTH, h );
      }
      
      menu.switchPanels();
    }

    private function getFlashVarInt( s:String ):int
    {
      return (vars[s] != null)
        ?	parseInt( vars[s] ) 
        :	0;
    }
    
    private function createCurCont( totalCount:uint ):void
    {
      cur_cont = new CacheCont( totalCount, PlayersContainer.ELEMS_ON_PAGE, 1 );
      switch ( menu.selectedLocation )
      {
      case "user":
        cont_user = cur_cont;
        break;
      case "search":
        cont_search = cur_cont;
        break;
      //case "my":
      default:
        cont_my = cur_cont;
        break;
      }
    }
    
    private function createContextMenu():void
    {
      var cm:ContextMenu = new ContextMenu();
      cm.hideBuiltInItems();
      var cmi1:ContextMenuItem = new ContextMenuItem( "Player version: " + VER );
      var cmi2:ContextMenuItem = new ContextMenuItem( "by Alexey Kharkov" );
      cmi1.addEventListener( ContextMenuEvent.MENU_ITEM_SELECT, function(e:ContextMenuEvent):void
      {
          navigateToURL( new URLRequest( "http://vkontakte.ru" ), "_blank" );
      });
      cmi2.addEventListener( ContextMenuEvent.MENU_ITEM_SELECT, function(e:ContextMenuEvent):void
      {
          navigateToURL( new URLRequest( "id5005272" ), "_blank" );
      });
      cm.customItems.push( cmi1 );
      cm.customItems.push( cmi2 );
      contextMenu = cm;
    }
    
    private function initMsgRect( msgRect:* ):void
    {
      msgRect.addEventListener( MsgRect.EVENT_SETTINGS, onOpenSettings );
      msgRect.addEventListener( MsgRect.EVENT_NEW, onButNew );
    }
    
    // ----------------------------------------------------------------------- Event handlers
    private function onMenu( e:Event ):void
    {
      if ( e.target is VK.MainMenu )
        goTo( e.target.selectedLocation );
    }
    
    private function onButEdit( e:MouseEvent ):void
    {
      cur_players.editMode = !cur_players.editMode;
      
      if ( cont_my )
        showPlayers();
      else
        goTo( cur_full_loc );
    }

    private function onButNew( e:* ):void
    {
      goTo( "new" );
    }

    private function onSettingsChanged( e:Object ):void
    {
      goTo( cur_full_loc );
    }
    
    private function onOpenSettings( e:Event ):void
    {
      if ( !(wrapper is Stage) )
        wrapper.external.showSettingsBox( 1 + 2 + 8 + 256 );
    }
    
    private function onUploaded( e:Event ):void
    {
      enGui( false );
      vkApi.saveAudio( newAudio.serverId, newAudio.audioId, newAudio.hash );
    }

    private function onSearch( e:Event ):void
    {
      search( searchInputField.value );
    }

    // ----------------------------------------------------------------------- Public static methods
    public static function clearLayout( obj:Sprite, fromIdx:uint = 0 ):void
    {
      while ( obj.numChildren > fromIdx )
        obj.removeChildAt( obj.numChildren - 1 );
    }

    public static function scrollTo( yy:uint ):void
    {
      if ( !(wrapper is Stage) )
        wrapper.external.scrollWindow( yy, 300 );
    }

  }
}
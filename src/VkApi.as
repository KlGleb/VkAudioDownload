package {
import flash.events.Event;
import flash.events.TimerEvent;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.net.URLVariables;
import flash.net.URLRequest;
import flash.net.URLRequestMethod;
import flash.net.URLLoader;
import flash.utils.Timer;

import utils.*;

/**
 * @author Alexey Kharkov
 */
public class VkApi {
    private var par:* = null;

    private var api_url:String = null;
    private var viewer_id:int = 0;
    private var app_id:int = 0;
    private var secret:String = null;
    private var sid:String = null;

    private var timer:Timer = null;

    private var rqCommon:BkRequest = null;

    // -------------------------------------- Request types.
    // Common requests.
    private static const LOC_GET:uint = 501; // Location strings

    // Audio requests.
    private static const AUDIO_GET:uint = 401;
    private static const AUDIO_SEARCH:uint = 402;
    private static const AUDIO_GET_LYRICS:uint = 403;
    private static const AUDIO_GET_UPLOAD_SERVER:uint = 404;
    private static const AUDIO_SAVE:uint = 405;
    private static const AUDIO_ADD:uint = 406;
    private static const AUDIO_DELETE:uint = 407;
    private static const AUDIO_RESTORE:uint = 408;
    private static const AUDIO_EDIT:uint = 409;
    private static const AUDIO_REORDER:uint = 410;


    //
    public function VkApi(par:*, api_url:String, viewer_id:int, app_id:int, secret:String, sid:String):void {
        this.par = par;
        this.api_url = api_url;
        this.viewer_id = viewer_id;
        this.app_id = app_id;
        this.secret = secret;
        this.sid = sid;
    }

    // ------------------------------------------------------------------------------ Common methods.
    public function getLocValues():void {
        var p_arr:Array = new Array();
        p_arr.push({pn: "method", pv: "language.getValues"});
        p_arr.push({pn: "all", pv: 1});

        rqCommon = new BkRequest(LOC_GET);
        sendRequestCommon(p_arr);
    }

    // ------------------------------------------------------------------------------ Audio methods.
    public function getAudio(userId:uint, need_user:Boolean):void {
        var p_arr:Array = new Array();
        p_arr.push({pn: "method", pv: "audio.get"});
        p_arr.push({pn: "uid", pv: userId});
        p_arr.push({pn: "need_user", pv: (need_user ? 1 : 0)});

        rqCommon = new BkRequest(AUDIO_GET);
        rqCommon.uid = (need_user ? userId : 0);
        sendRequestCommon(p_arr);
    }

    public function searchAudio(s:String, offset:uint, onlyWithLyrics:Boolean):void {
        var p_arr:Array = new Array();
        p_arr.push({pn: "method", pv: "audio.search"});
        p_arr.push({pn: "offset", pv: offset});
        p_arr.push({pn: "q", pv: s});
        p_arr.push({pn: "lyrics", pv: (onlyWithLyrics ? 1 : 0)});

        rqCommon = new BkRequest(AUDIO_SEARCH);
        sendRequestCommon(p_arr);
    }

    public function getLyrics(lyrics_id:uint):void {
        var p_arr:Array = new Array();
        p_arr.push({pn: "method", pv: "audio.getLyrics"});
        p_arr.push({pn: "lyrics_id", pv: lyrics_id});

        rqCommon = new BkRequest(AUDIO_GET_LYRICS);
        sendRequestCommon(p_arr);
    }

    public function getUploadServer():void {
        var p_arr:Array = new Array();
        p_arr.push({pn: "method", pv: "audio.getUploadServer"});

        rqCommon = new BkRequest(AUDIO_GET_UPLOAD_SERVER);
        sendRequestCommon(p_arr);
    }

    public function saveAudio(server:String, audio:String, hash:String):void {
        var p_arr:Array = new Array();
        p_arr.push({pn: "method", pv: "audio.save"});
        p_arr.push({pn: "server", pv: server});
        p_arr.push({pn: "audio", pv: audio});
        p_arr.push({pn: "hash", pv: hash});

        rqCommon = new BkRequest(AUDIO_SAVE);
        sendRequestCommon(p_arr);
    }

    public function addAudio(aid:uint, oid:int):void {
        var p_arr:Array = new Array();
        p_arr.push({pn: "method", pv: "audio.add"});
        p_arr.push({pn: "aid", pv: aid});
        p_arr.push({pn: "oid", pv: oid});

        rqCommon = new BkRequest(AUDIO_ADD);
        sendRequestCommon(p_arr);
    }

    public function deleteAudio(aid:uint, oid:int):void {
        var p_arr:Array = new Array();
        p_arr.push({pn: "method", pv: "audio.delete"});
        p_arr.push({pn: "aid", pv: aid});
        p_arr.push({pn: "oid", pv: oid});

        rqCommon = new BkRequest(AUDIO_DELETE);
        sendRequestCommon(p_arr);
    }

    public function restoreAudio(aid:uint):void {
        var p_arr:Array = new Array();
        p_arr.push({pn: "method", pv: "audio.restore"});
        p_arr.push({pn: "aid", pv: aid});

        rqCommon = new BkRequest(AUDIO_RESTORE);
        sendRequestCommon(p_arr);
    }

    public function editAudio(aid:uint, oid:int, artist:String, title:String, text:String, no_search:Boolean):void {
        var p_arr:Array = new Array();
        p_arr.push({pn: "method", pv: "audio.edit"});
        p_arr.push({pn: "aid", pv: aid});
        p_arr.push({pn: "oid", pv: oid});
        p_arr.push({pn: "artist", pv: artist});
        p_arr.push({pn: "title", pv: title});
        p_arr.push({pn: "text", pv: text});
        p_arr.push({pn: "no_search", pv: no_search});

        rqCommon = new BkRequest(AUDIO_EDIT);
        sendRequestCommon(p_arr);
    }

    public function reorderAudio(aid:uint, after:int, before:int):void {
        var p_arr:Array = new Array();
        p_arr.push({pn: "method", pv: "audio.reorder"});
        p_arr.push({pn: "aid", pv: aid});
        p_arr.push({pn: "after", pv: after});
        p_arr.push({pn: "before", pv: before});

        rqCommon = new BkRequest(AUDIO_REORDER);
        sendRequestCommon(p_arr);
    }

    // ------------------------------------------------------------------------------------ methods.
    private function srHelper(arr:Array, rq:BkRequest):URLVariables // sendRequestHelper
    {
        par.enGui(false);

        arr.push({pn: "api_id", pv: app_id});
        arr.push({pn: "sid", pv: sid});
        arr.push({pn: "v", pv: "3.0"});
        arr.push({pn: "format", pv: "JSON"});

        //var timestamp:int = new Date().valueOf();
        //arr.push( {pn: "timestamp", pv: timestamp} );

        //var randomNumber:int = Math.round( Math.random() * 100000000 );
        //arr.push( {pn: "randomNumber", pv: randomNumber} );

        if (Main.TEST_MODE)
            arr.push({pn: "test_mode", pv: "1"});

        arr.sortOn("pn");

        var url_vars:URLVariables = new URLVariables();
        for (var i:uint = 0; i < arr.length; i++)
            url_vars[(arr[i].pn)] = arr[i].pv;

        url_vars["sig"] = makeSig(arr);

        // init the current request
        rq.url_vars = url_vars;
        return url_vars;
    }

    // --------------------------------------------------------------
    private function sendRequestCommon(arr:Array):void {
        var url_vars:URLVariables = srHelper(arr, rqCommon);
        jsrHelper(url_vars, lchCommon);
    }

    private function jsrCommon(e:TimerEvent):void {
        jsrHelper(rqCommon.url_vars, lchCommon);
    }

    // --------------------------------------------------------------
    private function makeSig(arr:Array):String {
        var sig:String = "" + viewer_id;
        for (var i:uint = 0; i < arr.length; i++) {
            if (arr[i].pn != "sid")
                sig += arr[i].pn + "=" + arr[i].pv;
        }
        sig += secret;

        //Dbg.log( "vkApi.SIG: " + sig );

        return MD5.encrypt(sig);
    }

    // ------------------------------------------------------------------------------- Just-Send-Request methods
    private function jsrHelper(url_vars:URLVariables, handler_:*):void {
        var urlRequest:URLRequest = new URLRequest(api_url);
        urlRequest.method = URLRequestMethod.POST;
        urlRequest.data = url_vars;

        var ldr:URLLoader = new URLLoader();
        ldr.addEventListener(Event.COMPLETE, handler_);
        ldr.addEventListener(IOErrorEvent.IO_ERROR, errHandler);
        ldr.addEventListener(SecurityErrorEvent.SECURITY_ERROR, sequreErrHandler);

        ldr.load(urlRequest);
    }

    // -------------------------------------------------------------------------------- LoaderComplete handlers
    // LoaderComplete handler
    private function lchCommon(e:Event):void {
        var rq:BkRequest = lchHelper(e, rqCommon, jsrCommon);
        if (rq == null)
            return;

        switch (rq.type) {
            case LOC_GET:
                parseLoc(rq);
                break;
            case AUDIO_GET:
                parseAudio(rq);
                break;
            case AUDIO_SEARCH:
                parseAudio(rq);
                break;
            case AUDIO_GET_LYRICS:
                parseLyrics(rq);
                break;
            case AUDIO_GET_UPLOAD_SERVER:
                parseUploadServer(rq);
                break;
            case AUDIO_SAVE:
                parseSave(rq);
                break;
            case AUDIO_RESTORE:
                parseRestore(rq);
                break;
            case AUDIO_EDIT:
                parseEdit(rq);
                break;
            case AUDIO_ADD:
            case AUDIO_DELETE:
            case AUDIO_REORDER:
                // Nothing to parse.
                par.enGui(true);
                break;
        }
    }

    private function delayedCall(func:*, ms:int):void {
        timer = new Timer(ms, 1);
        timer.addEventListener("timer", func);
        timer.start();
    }

    private function lchHelper(e:Event, rq:BkRequest, handler_:*):BkRequest {
        var resultLoader:URLLoader = URLLoader(e.target);
        var s:String = resultLoader.data;

        //Dbg.log( "vkApi.lchHelper() <" + rq.type + ">\n" + s.substr(0,98) );
        //Dbg.log( "vkApi.lchHelper() <" + rq.type + ">\n" + s );

        var err:int = checkError(s);
        if (0 != err) {
            if (err == 6) // Too many requests per second
            {
                //Dbg.log( "   Too many requests per second! Reloading." );

                // Wait for 400 milliseconds before next request
                delayedCall(handler_, 400);
                return null;
            }

            if (err == 7) // Permission to perform this action is denied by user
            {
                par.noPermission();
                return null;
            }

            par.unkErr();
            return null;
        }

        rq.res = s;
        return rq;
    }

    // --------------------------------------------------------------------------- error handlers.
    private function errHandler(e:IOErrorEvent):void {
        //Dbg.log( "vkApi.errHandler( " + e.text + " )" );
        par.unkErr();
    }

    private function sequreErrHandler(e:SecurityErrorEvent):void {
        //Dbg.log( "vkApi.sequreErrHandler( " + e.text + " )" );
        par.unkErr();
    }


    // -------------------------------------------------------------------------- check error methods.
    private function checkError(s:String):int {
        var found:int = s.indexOf("\"error\"");
        if (found != 1)
            return 0;

        var i:int = 24;
        while (i < s.length && s.charAt(i) != ",")
            i++;

        var s1:String = s.substring(23, i);
        return parseInt(s1);
    }

    // -------------------------------------------------------------------------- Helper methods
    private function delQuotes(s_:String):String {
        var s:String = s_;
        if (s) {
            s = s.replace(/<br>/g, "\n");
            s = s.replace(/&amp;/g, "\&");
            s = s.replace(/&quot;/g, "\"");
            s = s.replace(/&\#34;/g, "\"");
            s = s.replace(/&\#39;/g, "\'");
        }
        return s;
    }

    // ============================================================================================= 
    // ------------------------------------------------------------------- Common parsing methods.
    private function parseLoc(rq:BkRequest):void {
        parseLocStr(rq.res);
    }

    public function parseLocStr(s:String):void {
        var jsonObj:* = MyJson.decode(s);
        var res:Array = jsonObj.response;

        par.onLocValues(res[0]);
    }

    // ------------------------------------------------------------------- Audio parsing methods.
    private function parseAudio(rq:BkRequest):void {
        var jsonObj:* = MyJson.decode(rq.res);
        var res:Array = jsonObj.response;

        if (res.length == 0 || res[0] == 0) {
            par.onAudioList(0, []);
            return;
        }

        var totalCount:uint = (rq.type == AUDIO_GET) ? 0 : res[0];
        var from:uint = (rq.type == AUDIO_GET) ? 0 : 1;
        var audios:Array = new Array();

        if (rq.uid > 0) {
            par.onUserName(res[from].name_gen);
            from++;
        }

        for (var i:int = from; i < res.length; ++i) {
            var p:* = res[i];
            try {
                audios.push({
                    "url": p.url, "aid": p.aid, "owner_id": p.owner_id, "artist": delQuotes(p.artist),
                    "title": delQuotes(p.title), "duration": p.duration, "lyrics_id": p.lyrics_id
                });
            } catch (e:Error) {
            }
        }

        totalCount = Math.min(Math.max(audios.length, totalCount), 1000);

        par.onAudioList(totalCount, audios);
    }

    private function parseLyrics(rq:BkRequest):void {
        var jsonObj:* = MyJson.decode(rq.res);
        var p:* = jsonObj.response[0];
        par.onLyrics(p.lyrics_id, delQuotes(p.text));
    }

    private function parseUploadServer(rq:BkRequest):void {
        var jsonObj:* = MyJson.decode(rq.res);
        var p:* = jsonObj.response[0];
        par.onUploadServer(p.upload_url);
    }

    private function parseSave(rq:BkRequest):void {
        var jsonObj:* = MyJson.decode(rq.res);
        var p:* = jsonObj.response[0];
        par.onSaved(parseInt(p.aid), parseInt(p.owner_id), delQuotes(p.artist), delQuotes(p.title), parseInt(p.duration), p.url);
    }

    private function parseRestore(rq:BkRequest):void {
        var jsonObj:* = MyJson.decode(rq.res);
        var p:* = jsonObj.response[0];
        par.onRestored(parseInt(p.aid), parseInt(p.owner_id), delQuotes(p.artist), delQuotes(p.title), parseInt(p.duration), p.url);
    }

    private function parseEdit(rq:BkRequest):void {
        var jsonObj:* = MyJson.decode(rq.res);
        var lyrics_id:uint = jsonObj.response;
        par.onEdited(lyrics_id);
    }

}
}
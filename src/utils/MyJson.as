package utils {
/**
 * @author Alexey Kharkov
 */
public class MyJson {
    private var s:String = null;
    private var len:int = 0;
    private var ii:int = 0;

    private var o:Object = null;
    private var nm:String = null;
    private var ri:int = 0;
    private var rs:String = null;
    private var ra:Array = null;

    public static function decode(s_:String):* {
        var obj:MyJson = new MyJson(s_);
        return obj.o;
    }

    public function MyJson(s_:String, from:int = 0):void {
        s = s_;

        len = s.length;
        ii = from;

        var ch:String = s.charAt(ii);

        switch (ch) {
            case '"':
                readStr();

                ch = s.charAt(++ii);
                if (ch == ':') {
                    nm = rs;
                    var gg:MyJson = new MyJson(s, ii + 1);
                    ii = gg.ii;
                    ri = gg.ri;
                    rs = gg.rs;
                    ra = gg.ra;
                }
                return;

            case '{':
            case '[':
                readObj();
                return;

            case 't': // == true
                ii += 4;
                ri = 1;
                break;

            case 'f': // == false
                ii += 5;
                break;

            case 'n': // == null
                ii += 4;
                rs = "";
                break;

            default:
                // see if we can read a number
                if (isDigit(ch) || ch == '-') {
                    readNum();
                } else {
                    //parseError( "Unexpected " + ch + " encountered" );
                }
        }
    }

    private function readNum():void {
        var i0:int = ii;
        while (ii < len - 1) {
            var ch:String = s.charAt(++ii);

            if (!isDigit(ch)) {
                ri = parseInt(s.substring(i0, ii));
                break;
            }
        }

        //trace( "   ri " + ri )
    }

    private function integr(gg:MyJson):void {
        var oo:* = null;
        if (gg.o != null)
            oo = gg.o;
        else if (gg.ra != null)
            oo = gg.ra;
        else if (gg.rs != null)
            oo = gg.rs;
        else
            oo = gg.ri;

        if (gg.nm != null) {
            o[gg.nm] = oo;
            ra.push(o);
        } else
            ra.push(oo);
    }

    private function readObj():void {
        o = new Object();
        ra = new Array();

        while (ii < len - 1) {
            var gg:MyJson = new MyJson(s, ii + 1);
            integr(gg);

            ii = gg.ii;

            var ch:String = s.charAt(ii);
            switch (ch) {
                case '}':
                case ']':
                    ++ii;
                    return;
            }
        }
    }

    private function readStr():void {
        rs = "";

        while (ii < len - 1) {
            var ch:String = s.charAt(++ii);

            if (ch == '"')
                return;

            if (ch != '\\') {
                // didn't have to unescape, so add the Stringacter to the ss
                rs += ch;
            } else {
                // unescape the escape sequences in the string
                ch = s.charAt(++ii);

                switch (ch) {
                    case '"': // quotation mark
                        rs += '"';
                        break;

                    case '/':	// solidus
                        rs += "/";
                        break;

                    case '\\':	// reverse solidus
                        rs += '\\';
                        break;

                    case 'b':	// bell
                        rs += '\b';
                        break;

                    case 'f':	// form feed
                        rs += '\f';
                        break;

                    case 'n':	// newline
                        rs += '\n';
                        break;

                    case 'r':	// carriage return
                        rs += '\r';
                        break;

                    case 't':	// horizontal tab
                        rs += '\t'
                        break;

                    //case 'u':
                    // TODO: convert a unicode escape sequence
                    //break;

                    default:
                        // couldn't unescape the sequence, so just
                        // pass it through
                        rs += '\\' + ch;

                }

            }
        }

    }

    private function isDigit(ch:String):Boolean {
        return ( ch >= '0' && ch <= '9' );
    }

}
}
package utils {
import flash.net.*;

/**
 * @author Alexey Kharkov
 */
public class BkRequest {
    public var url_vars:URLVariables = null;

    public var type:uint = 0;
    public var uid:uint = 0;

    public var res:String = null;

    // -------------------------------------------------------------------------- Methods
    public function BkRequest(type:uint):void {
        this.type = type;
    }

}
}

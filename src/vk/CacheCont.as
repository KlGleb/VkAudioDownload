// Container for Caching support

package vk
{
  /**
   * @author Alexey Kharkov
   */
  public class CacheCont
  {
    private var elems:Array = null;
    private var plf:Array = null; // "Page Loaded" flags
    private var cur_p:uint = 0; // current page
    private var p_cnt:uint = 0; // pages cont
    private var load_from:uint = 0;

    private var elemsOnPage:uint = 0;
    private var pagesToLoad:uint = 0;
    
    public function CacheCont( totalCount:uint, elemsOnPage:uint = 10, pagesToLoad:uint = 9 ):void
    {
      this.elemsOnPage = elemsOnPage;
      this.pagesToLoad = pagesToLoad;
      
      if ( totalCount > 0 )
      {
        elems = new Array( totalCount );
        p_cnt = Math.ceil( elems.length / elemsOnPage );

        plf = new Array( p_cnt );
        for ( var i:int = 0; i < p_cnt; ++i )
        {
          plf[i] = false;
        }
      }
    }

    public function addElems( arr:Array, offset:uint = 0 ):void
    {
      if ( elems == null )
        return;
      
      for ( var i:uint = 0; i < arr.length; ++i )
      {
        elems[offset + i] = arr[i];
      }
    }
    
    public function markElemsAsLoaded( from:uint, count:uint, totalCount:uint ):void
    {
      if ( plf == null )
        return;
      
      var k1:int = Math.floor( from / elemsOnPage );

      var k2:int = (from + pagesToLoad * elemsOnPage >= totalCount)
        ?  k1 + pagesToLoad     // mark last pages as loaded (even if they are empty)
        :  k1 + Math.ceil( count / elemsOnPage );

      k2 = Math.min( plf.length, k2 );

      for ( var i:int = k1; i < k2; ++i )
      {
        plf[i] = true;
      }
    }
    
    public function getAt( i:uint ):*
    {
      return (elems == null) ? null : elems[i];
    }
    
    public function get length():uint
    {
      return (elems == null) ? 0 : elems.length;
    }

    public function get curPage():uint
    {
      return cur_p;
    }
    
    public function set curPage( val:uint ):void
    {
      cur_p = val;
    }
    
    public function curPageLoaded():Boolean
    {
      return isLoaded( cur_p );
    }
    
    public function isLoaded( idx:uint ):Boolean
    {
      if ( plf == null )
        return true;
      
      if ( idx > plf.length )
        return true;
      
      return plf[idx];
    }
    
    public function get curIdx():uint
    {
      return cur_p * elemsOnPage;
    }

    public function get loadFrom():uint // Should be called before loadCount
    {
      if ( plf == null )
        return 0;
      
      var from:int = cur_p;
      if ( p_cnt > from )
      {
        var k:int = 1; // not 0!
        while ( from > 0  &&  k < pagesToLoad )
        {
          ++k;
          from --;

          if ( plf[from] )
          {
            from ++;
            break;
          }
        }
      }
      
      load_from = Math.max( from, 0 );
      return elemsOnPage * load_from;
    }
/*
    public function get loadCount():uint // Should be called after loadFrom
    {
      if ( plf == null )
        return 0;

      var to:int = cur_p;
      if ( p_cnt <= to )
        to += pagesToLoad;
      else
      {
        var k:int = 0;
        while ( to < p_cnt  &&  k < pagesToLoad )
        {
          ++k;

          if ( plf[to] )
            break;
          
          to ++;
        }
      }
      
      return elemsOnPage * Math.min( to - load_from, 10 );
    }
/* */
	}
}
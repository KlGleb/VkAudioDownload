package locale
{
  import flash.display.Stage;
  import locale.Loc;

  /**
   * @author Alexey Kharkov
   */
  public class Loc
  {
    public static var cur:* = null;
    
    public static function initLoc( obj:* ):void
    {
      if ( !(obj is Number) )
        cur = obj;
      else
        initLocRus();
    }
    
    public static function audioCountStr( count:uint, i1:uint, i2:uint ):String
    {
      var s:String = count + " " + audioCountStrHelper( count );
      if ( i1 > 1  ||  i2 < count )
      {
        s += " (" + Loc.cur.displaying + " " + i1 + "-" + i2 + ")";
      }
      return s;
    }
    
    private static function audioCountStrHelper( count:uint ):String
    {
      if ( !(Main.wrapper is Stage)  &&  cur.audiotrack is Array )
        return Main.wrapper.lang.langNumeric( count, cur.audiotrack );
      
      //return "Audio File(s)";
      return _padej(count, "Аудиозапись", "Аудиозаписи", "Аудиозаписей");
    }

    
    public static function initLocRus():void
    {
      cur = new Object();
      cur.name = "Мои Аудиозаписи";
      cur.artist = "Исполнитель";
      cur.title = "Название";
      cur.optional = "Дополнительно";
      cur.lyrics = "Слова песни";
      cur.no_search = "Не выводить при поиске";
      cur.needAudioAccess = "Нужно разрешить доступ к Вашим аудиозаписям";
      cur.openSettings = "Открыть настройки";
      cur.noAudio1 = "Здесь Вы можете хранить Ваши аудиозаписи";
      cur.addTrack = "Добавить аудиозапись";
      cur.noAudio2 = "Ни одной аудиозаписи не найдено";
      cur.chooseFile = "Выберите аудиозапись на Вашем компьютере";
      cur.restict = "Ограничения";
      cur.restrict1 = "Аудиофайл не должен превышать 10 Мб и должен быть в формате MP3";
      cur.restrict2 = "Аудиофайл не должен нарушать авторские права";
      cur.chooseF = "Выбрать файл";
      cur.cancel = "Отмена";
      cur.youCanSearch = "Вы также можете добавить аудиозапись из числа уже загруженных файлов";
      cur.byUsing = "воспользовавшись";
      cur.audioSearch = "поиском по аудио";
      cur.edit = "редактировать";
      cur.del = "удалить";
      cur.deleted = "Аудиозапись удалена";
      cur.undo = "Восстановить";
      cur.add = "Добавить";
      cur.added = "Добавлено";
      cur.myAudio = "Мои аудиозаписи";
      cur.userAudio = "Аудиозаписи пользователя";
      cur.search = "Поиск";
      cur.newAudio = "Новая аудиозапись";
      cur.audioLoaded = "Аудиозапись успешно загружена";
      cur.audioU = "Аудиозаписи";
      cur.enterSearchStr = "Пожалуйста, введите название композиции или исполнителя";
      cur.withLyrics = "С текстом";
      cur.editAudio = "Редактирование аудиозаписи";
      cur.editBig = "Редактировать";
      cur.displaying = "выводятся";
      cur.viewAudio = "Просмотр аудиозаписи";
      cur.close = "Закрыть";

    }
	
	/**
	 * Склоняет строковое значение, зависящее от числа
	 * @param	count 
	 * @param	nominative им.п./ед.ч. (одна банкнота)
	 * @param	genitive_singular род.п./ед.ч. (две банкноты)
	 * @param	genitive_plural род.п./мн.ч. (стопитцот банкнот)
	 */
	private static function _padej(count:int, nominative:String, genitive_singular:String, genitive_plural:String):String {
		var result:String = "";
		var last_digit:int = count % 10;
		var last_two_digits:int = count % 100;
		if ((last_digit == 1) && (last_two_digits != 11) ) { 
			result = nominative;
		}else if (( (last_digit == 2) && (last_two_digits != 12)) || ((last_digit == 3) && (last_two_digits != 13)) || ((last_digit == 4) && (last_two_digits != 14))) {
			 result = genitive_singular;

		}else { 
			result = genitive_plural;
		}
		
		return(result);
	}
  }
}
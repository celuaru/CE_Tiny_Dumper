--Author: MasterGH, 03.01.2015, Gamehacklab[RU] (http://gamehacklab.ru)

frmTinyDumper  = createFormFromFile(getCheatEngineDir().."\\autorun\\frmTinyDumper.xml")
frmTinyDumper.Caption = 'Tiny Dumper [CE Lua Plugin, ver 1.2]'

-----------[[ РАБОТА С КЕШ ТАБЛИЦЕЙ ]]-----------
local tableData = {}

-- Добавить запись в таблицу
function AddRecordToTable(address, sizeMem, unicalSymbolName, cashBytes)
	local line = {}
	table.insert(line, address)
	table.insert(line, sizeMem)
	table.insert(line, unicalSymbolName)
	table.insert(line, cashBytes)
	table.insert(tableData, line)
end

-- Удалить запись из таблицы по уникальной метке
function RemoveRecordFromTable(unicalSymbolName)
	for i = 1, #tableData do
		if(tableData[i][3] == unicalSymbolName) then
			table.remove(tableData, i)
			return
		end
	end
end

-- Возвращает запись по уникальной метке
function FindRecordInTable(unicalSymbolName)
	for i = 1, #tableData do
		if(tableData[i][3] == unicalSymbolName) then
			return tableData[i]
		end
	end
	return nil
end





-----------[[ ОСНОВНЫЕ ФУНКЦИИ ]]-----------

-- Кнопка, по которой происходит дамп памяти
function CEButtonDumpClick(sender)
	if (getOpenedProcessID() == 0) then
		messageDialog('No target any process', mtError, mbOK)
		return
	end
	
	local userSizeMem = frmTinyDumper.CEEditSize.Text
	local userAddress = frmTinyDumper.CEEditAddress.Text
	local userRegisterSymbol = frmTinyDumper.CEEditRegisterSymbol.Text
	
	if (userSizeMem == '') then
		messageDialog('UserSizeMem <= 0', mtError, mbOK)
		return
	end

	if (address == '') then
		messageDialog('UserAddress is empty', mtError, mbOK)
		return
	end

	if (registerSymbol == '') then
		messageDialog('UserRegisterSymbol is empty', mtError, mbOK)
		return
	end
	
	local strings = frmTinyDumper.CEListBoxSymbols.Items
	local count = strings.Count - 1

	for i = 0, count do
		if(strings[i] == userRegisterSymbol) then
			messageDialog('UserRegisterSymbol '..userRegisterSymbol..' is not unical', mtError, mbOK)
			return
		end
	end
	
	strings.add(userRegisterSymbol)
		
	autoAssemble(string.format([[alloc(%s,%s)
registersymbol(%s)
%s:
readmem(%s,%s)]], userRegisterSymbol, userSizeMem, userRegisterSymbol, userRegisterSymbol, userAddress, userSizeMem))

	local cashBytes = readBytes(userAddress, tonumber(userSizeMem), true)
    AddRecordToTable(userAddress, userSizeMem, userRegisterSymbol, cashBytes)
end

-- Копирование информации о записи в буффер обмена
function OnClickCopySymbolToBuffer(sender)
	local ceListBoxSymbols = frmTinyDumper.CEListBoxSymbols
	local strings = ceListBoxSymbols.Items
	local count = strings.Count - 1
	local textBuffer = ''
	for i = 0, count do
	  if(ceListBoxSymbols.Selected[i]) then
		textBuffer = textBuffer..string.format('%s', strings[i])
		writeToClipboard(textBuffer)
		return
	  end
	end
end
-- Удаление записи из списка
function OnClickRemove(sender)
	local ceListBoxSymbols = frmTinyDumper.CEListBoxSymbols
	local strings = ceListBoxSymbols.Items
	local count = strings.Count - 1
	for i = 0, count do
		if(ceListBoxSymbols.Selected[i]) then
			local symbolName = string.format('%s', strings[i])
			strings.delete(i)
			autoAssemble(string.format([[
dealloc(%s)
unregistersymbol(%s)
]], symbolName, symbolName))
			RemoveRecordFromTable(symbolName)
			return
		end
	end
end

-- Обработчик выделения записи обновляет данные в полях формы
function CEListBoxSymbolsSelectionChange(sender, user)
	local ceListBoxSymbols = frmTinyDumper.CEListBoxSymbols
	local strings = ceListBoxSymbols.Items
	local count = strings.Count - 1

	for i = 0, count do
	  if(ceListBoxSymbols.Selected[i]) then
		userRegisterSymbol = strings[i]
		local line = FindRecordInTable(userRegisterSymbol)
		frmTinyDumper.CEEditAddress.Text = line[1]
	    frmTinyDumper.CEEditSize.Text = line[2]
	    frmTinyDumper.CEEditRegisterSymbol.Text = userRegisterSymbol
		return
	  end
	end
end

-- Показывает TinyDumper из главного меню в окне Дизассемблера
function OnClickMenuItemDT()
	frmTinyDumper.Show()
end

-- Сохраняет все дампы в файл

-- Функция, которая вызовется после закрытия диалога сохранения
function OnCloseSaveDialog(argFrmSaveDialog)
	local path = argFrmSaveDialog.FileName
	local stringList = createStringlist()

	for i = 1, #tableData do
		local adress = tableData[i][1]
		local size = tableData[i][2]
		local unicalName = tableData[i][3]
		local tablesReadBytes = tableData[i][4] --readBytes(adress, tonumber(size), true)
		if(tablesReadBytes == nil) then
			messageDialog('TablesReadBytes is nil', mtError, mbOK)
			return
		end
		local strBytes = table.concat(tablesReadBytes, " ")
		local data = string.format("<TABLE>%s;%s;%s;%s</TABLE>", adress, size, unicalName, strBytes)
		stringList.add(data)
	end

	stringList.saveToFile(path)
	stringList.destroy()
end
	
function OnClickMenuItemSaveAllDumps()
	if (getOpenedProcessID() == 0) then
		messageDialog('No target any process', mtError, mbOK)
		return
	end
	if (#tableData == 0) then
		messageDialog('Table is empty', mtWarning, mbOK)
		return
	end
	if(frmSaveDialog == nil) then
		frmSaveDialog = createSaveDialog(nil)
	end
	frmSaveDialog.DefaultExt = '.tinyDumper'
	frmSaveDialog.FileName = fileName
	frmSaveDialog.Filter = '*.tinyDumper'
	frmSaveDialog.FilterIndex = 0
	frmSaveDialog.OnClose = OnCloseSaveDialog
	frmSaveDialog.Execute()
end


function string:split( inSplitPattern, outResults )
   if not outResults then
      outResults = { }
   end
   local theStart = 1
   local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
   while theSplitStart do
      table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
      theStart = theSplitEnd + 1
      theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
   end
   table.insert( outResults, string.sub( self, theStart ) )
   return outResults
end

-- Функция, которая вызовется после закрытия диалога загрузки дампов
function OnCloseOpenDialog(argFrmOpenDialog)

	if (getOpenedProcessID() == 0) then
		messageDialog('No target any process', mtError, mbOK)
		return
	end
	
	local path = argFrmOpenDialog.FileName
	-- Очищаем старую таблицу
	OnClickMenuItemClear()
	
	local stringList = createStringlist()
	stringList.loadFromFile(path)
	local text = stringList.Text
	-- Ищем вхождения каждого дампа
	for att,cont in text:gmatch'<TABLE%s*(.-)>(.-)</TABLE>' do

		local tableSplitData = cont:split(";")
		
		local userAddress 			= tableSplitData[1]
		local userSizeMem	 		= tableSplitData[2]
		local userRegisterSymbol	= tableSplitData[3]
		local strBytes				= tableSplitData[4]
		local byteTables 			= strBytes:split(" ")
		
		
		local strings = frmTinyDumper.CEListBoxSymbols.Items	
		strings.add(userRegisterSymbol)
			
		autoAssemble(string.format([[alloc(%s,%s)
registersymbol(%s)
]], userRegisterSymbol, userSizeMem, userRegisterSymbol))
	
		AddRecordToTable(userAddress, userSizeMem, userRegisterSymbol, byteTables)
		
		writeBytes(getAddress(userRegisterSymbol), byteTables)
	end

	stringList.destroy()
end


-- Загружает дампы в процессы игры из файла
function OnClickMenuItemLoadAllDumps()
	if (getOpenedProcessID() == 0) then
		messageDialog('No target any process', mtWarning, mbOK)
		return
	end
	
	
	if (#tableData > 0) then
		local stateUnswer = messageDialog('The table will be lost. You sure?', mtConfirmation, mbYes, mbNo)
		if (stateUnswer ~= mrYes) then
			return
		end
	end	
	
	if(frmOpenDialog == nil) then
		frmOpenDialog = createOpenDialog(nil)
	end
	
	frmOpenDialog.DefaultExt = '.tinydumper'
	frmOpenDialog.FileName = fileName
	frmOpenDialog.Filter = '*.tinydumper'
	frmOpenDialog.FilterIndex = 0
	frmOpenDialog.OnClose = OnCloseOpenDialog
	frmOpenDialog.Execute()
end

-- Очистить все дампы
function OnClickMenuItemClear()
	local ceListBoxSymbols = frmTinyDumper.CEListBoxSymbols
	local strings = ceListBoxSymbols.Items
	local count = strings.Count - 1

	for i = 0, count do
		local symbolName = string.format('%s', strings[i])
		autoAssemble(string.format([[
dealloc(%s)
unregistersymbol(%s)
]], symbolName, symbolName))
		RemoveRecordFromTable(symbolName)
	end

	strings.clear()
end


-- Переподключает дампы
function OnClickMenuRetargetDumps()
	if (getOpenedProcessID() == 0) then
		messageDialog('No target any process', mtWarning, mbOK)
		return
	end
	
	if (#tableData > 0) then
		local stateUnswer = messageDialog('All dumps will be rewrite. You sure?', mtConfirmation, mbYes, mbNo)
		if (stateUnswer ~= mrYes) then
			return
		end
	end	

	for i = 1, #tableData do
		local address = tableData[i][1]
		local sizeMem = tableData[i][2]
		local unicalSymbolName = tableData[i][3]
		local cashBytes = tableData[i][4]
		
		autoAssemble(string.format([[
dealloc(%s)
unregistersymbol(%s)
]], unicalSymbolName, unicalSymbolName))

		autoAssemble(string.format([[alloc(%s,%s)
registersymbol(%s)
]], unicalSymbolName, sizeMem, unicalSymbolName))
		
		writeBytes(getAddress(unicalSymbolName), cashBytes)
	end
end

-----------[[ ПОДКЛЮЧЕНИЕ И НАСТРОЙКА ПЛАГИНА ]]-----------
-- Проверяет существование формы
if(frmTinyDumper == nil) then
	messageDialog('Can not find frmTinyDumper', mtError, mbOK)
	return
end

-- Добавление подменю '* TinyDumper [Plugin]' в иерархию меню в окне Дизассемблера
local menuItems = getMemoryViewForm().findComponentByName('MainMenu1').Items
local count = menuItems.Count - 1
frmSaveDialog = nil
frmOpenDialog = nil

for i = 0, count do
	local item = menuItems.getItem(i)
	if( (item.Caption == 'Tools') or (item.Caption == 'Инструменты') ) then
		local mi = createMenuItem(popupmenu)
		menuItem_setCaption(mi, '* TinyDumper [Plugin]')
		menuItem_onClick(mi, OnClickMenuItemDT)
		item.add(mi)
		break
	end
end

-- Еще пару менюшек для сохранения и загрузки дампов
--Save to file - сохранить дамп
	local mi = createMenuItem(popupmenu)
	menuItem_setCaption(mi, 'Save to file')
	menuItem_onClick(mi, OnClickMenuItemSaveAllDumps)
	frmTinyDumper.PopupMenu1.Items.add(mi)
--Load from file - загрузить дамп
	local mi = createMenuItem(popupmenu)
	menuItem_setCaption(mi, 'Load from file')
	menuItem_onClick(mi, OnClickMenuItemLoadAllDumps)
	frmTinyDumper.PopupMenu1.Items.add(mi)
--Remove all records - удалить все дампы
	local mi = createMenuItem(popupmenu)
	menuItem_setCaption(mi, 'Remove all records')
	menuItem_onClick(mi, OnClickMenuItemClear)
	frmTinyDumper.PopupMenu1.Items.add(mi)
--Retarget dumps - переподключает дампы
	local mi = createMenuItem(popupmenu)
	menuItem_setCaption(mi, 'Rewrite dumps')
	menuItem_onClick(mi, OnClickMenuRetargetDumps)
	frmTinyDumper.PopupMenu1.Items.add(mi)
	
-- Поправки в названии
	frmTinyDumper.PopupMenu1.Items[1].Caption = 'Remove selected'

-- Подключение функций-обработчиков
frmTinyDumper.CEButtonDump.OnClick = CEButtonDumpClick
frmTinyDumper.PopupMenu1.Items[0].OnClick = OnClickCopySymbolToBuffer
frmTinyDumper.PopupMenu1.Items[1].OnClick = OnClickRemove
setMethodProperty(frmTinyDumper.CEListBoxSymbols, 'OnSelectionChange', CEListBoxSymbolsSelectionChange)
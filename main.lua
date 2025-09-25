-- Love2D 连连看游戏
-- 游戏配置
local GRID_WIDTH = 10
local GRID_HEIGHT = 8
local TILE_SIZE = 50
local TILE_TYPES = 6
local GAME_WIDTH = GRID_WIDTH * TILE_SIZE
local GAME_HEIGHT = GRID_HEIGHT * TILE_SIZE

-- 游戏状态
local gameState = {
    grid = {},
    selectedTile = nil,
    score = 0,
    timeLeft = 300, -- 5分钟
    gameOver = false,
    won = false
}

-- 颜色定义
local colors = {
    {1, 0.2, 0.2},    -- 红色
    {0.2, 1, 0.2},    -- 绿色
    {0.2, 0.2, 1},    -- 蓝色
    {1, 1, 0.2},      -- 黄色
    {1, 0.2, 1},      -- 紫色
    {0.2, 1, 1},      -- 青色
}

-- 字体变量
local chineseFont

-- 初始化游戏
function love.load()
    love.window.setTitle("连连看游戏")
    love.window.setMode(GAME_WIDTH + 280, GAME_HEIGHT + 150)
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
    
    -- 加载本地中文字体
    local success, font = pcall(love.graphics.newFont, "font.otf", 16)
    if success then
        chineseFont = font
        print("成功加载中文字体")
    else
        -- 回退到默认字体
        chineseFont = love.graphics.newFont(18)
        print("字体加载失败，使用默认字体")
    end
    love.graphics.setFont(chineseFont)
    
    -- 初始化网格
    initializeGrid()
    
    -- 确保有解
    while not hasPossibleMoves() do
        initializeGrid()
    end
end

-- 初始化游戏网格
function initializeGrid()
    gameState.grid = {}
    local tiles = {}
    
    -- 创建成对的方块
    local totalTiles = GRID_WIDTH * GRID_HEIGHT
    for i = 1, totalTiles / 2 do
        local tileType = ((i - 1) % TILE_TYPES) + 1
        table.insert(tiles, tileType)
        table.insert(tiles, tileType)
    end
    
    -- 打乱方块
    for i = #tiles, 2, -1 do
        local j = math.random(i)
        tiles[i], tiles[j] = tiles[j], tiles[i]
    end
    
    -- 填充网格
    local index = 1
    for y = 1, GRID_HEIGHT do
        gameState.grid[y] = {}
        for x = 1, GRID_WIDTH do
            gameState.grid[y][x] = tiles[index]
            index = index + 1
        end
    end
end

-- 检查是否还有可能的移动
function hasPossibleMoves()
    for y1 = 1, GRID_HEIGHT do
        for x1 = 1, GRID_WIDTH do
            if gameState.grid[y1][x1] > 0 then
                for y2 = 1, GRID_HEIGHT do
                    for x2 = 1, GRID_WIDTH do
                        if gameState.grid[y2][x2] > 0 and 
                           (x1 ~= x2 or y1 ~= y2) and
                           gameState.grid[y1][x1] == gameState.grid[y2][x2] then
                            if canConnect(x1, y1, x2, y2) then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

-- 检查两个方块是否可以连接（连连看核心算法）
function canConnect(x1, y1, x2, y2)
    -- 直接连接
    if canDirectConnect(x1, y1, x2, y2) then
        return true
    end
    
    -- 一个转角连接
    if canOneCornerConnect(x1, y1, x2, y2) then
        return true
    end
    
    -- 两个转角连接
    if canTwoCornerConnect(x1, y1, x2, y2) then
        return true
    end
    
    return false
end

-- 检查直接连接
function canDirectConnect(x1, y1, x2, y2)
    if x1 == x2 then
        -- 垂直连接
        local minY, maxY = math.min(y1, y2), math.max(y1, y2)
        for y = minY + 1, maxY - 1 do
            if y >= 1 and y <= GRID_HEIGHT and x1 >= 1 and x1 <= GRID_WIDTH then
                if gameState.grid[y][x1] > 0 then
                    return false
                end
            end
        end
        return true
    elseif y1 == y2 then
        -- 水平连接
        local minX, maxX = math.min(x1, x2), math.max(x1, x2)
        for x = minX + 1, maxX - 1 do
            if y1 >= 1 and y1 <= GRID_HEIGHT and x >= 1 and x <= GRID_WIDTH then
                if gameState.grid[y1][x] > 0 then
                    return false
                end
            end
        end
        return true
    end
    return false
end

-- 检查一个转角连接
function canOneCornerConnect(x1, y1, x2, y2)
    -- 尝试转角点 (x1, y2)
    if isValidPosition(x1, y2) then
        if x1 >= 1 and x1 <= GRID_WIDTH and y2 >= 1 and y2 <= GRID_HEIGHT then
            if gameState.grid[y2][x1] == 0 then
                if canDirectConnect(x1, y1, x1, y2) and canDirectConnect(x1, y2, x2, y2) then
                    return true
                end
            end
        else
            -- 边界外视为空位置，可以通过
            if canDirectConnect(x1, y1, x1, y2) and canDirectConnect(x1, y2, x2, y2) then
                return true
            end
        end
    end
    
    -- 尝试转角点 (x2, y1)
    if isValidPosition(x2, y1) then
        if x2 >= 1 and x2 <= GRID_WIDTH and y1 >= 1 and y1 <= GRID_HEIGHT then
            if gameState.grid[y1][x2] == 0 then
                if canDirectConnect(x1, y1, x2, y1) and canDirectConnect(x2, y1, x2, y2) then
                    return true
                end
            end
        else
            -- 边界外视为空位置，可以通过
            if canDirectConnect(x1, y1, x2, y1) and canDirectConnect(x2, y1, x2, y2) then
                return true
            end
        end
    end
    
    return false
end

-- 检查两个转角连接
function canTwoCornerConnect(x1, y1, x2, y2)
    -- 向左扩展
    for x = x1 - 1, 0, -1 do
        if not isValidPosition(x, y1) then
            break
        end
        if x >= 1 and x <= GRID_WIDTH and y1 >= 1 and y1 <= GRID_HEIGHT and gameState.grid[y1][x] > 0 then
            break
        end
        if canOneCornerConnect(x, y1, x2, y2) then
            return true
        end
    end
    
    -- 向右扩展
    for x = x1 + 1, GRID_WIDTH + 1 do
        if not isValidPosition(x, y1) then
            break
        end
        if x >= 1 and x <= GRID_WIDTH and y1 >= 1 and y1 <= GRID_HEIGHT and gameState.grid[y1][x] > 0 then
            break
        end
        if canOneCornerConnect(x, y1, x2, y2) then
            return true
        end
    end
    
    -- 向上扩展
    for y = y1 - 1, 0, -1 do
        if not isValidPosition(x1, y) then
            break
        end
        if x1 >= 1 and x1 <= GRID_WIDTH and y >= 1 and y <= GRID_HEIGHT and gameState.grid[y][x1] > 0 then
            break
        end
        if canOneCornerConnect(x1, y, x2, y2) then
            return true
        end
    end
    
    -- 向下扩展
    for y = y1 + 1, GRID_HEIGHT + 1 do
        if not isValidPosition(x1, y) then
            break
        end
        if x1 >= 1 and x1 <= GRID_WIDTH and y >= 1 and y <= GRID_HEIGHT and gameState.grid[y][x1] > 0 then
            break
        end
        if canOneCornerConnect(x1, y, x2, y2) then
            return true
        end
    end
    
    return false
end

-- 检查位置是否有效
function isValidPosition(x, y)
    return x >= 0 and x <= GRID_WIDTH + 1 and y >= 0 and y <= GRID_HEIGHT + 1
end

-- 更新游戏状态
function love.update(dt)
    if not gameState.gameOver then
        gameState.timeLeft = gameState.timeLeft - dt
        
        if gameState.timeLeft <= 0 then
            gameState.gameOver = true
        end
        
        -- 检查是否获胜
        local remainingTiles = 0
        for y = 1, GRID_HEIGHT do
            for x = 1, GRID_WIDTH do
                if gameState.grid[y][x] > 0 then
                    remainingTiles = remainingTiles + 1
                end
            end
        end
        
        if remainingTiles == 0 then
            gameState.won = true
            gameState.gameOver = true
        elseif not hasPossibleMoves() then
            gameState.gameOver = true
        end
    end
end

-- 鼠标点击处理
function love.mousepressed(x, y, button)
    if button == 1 and not gameState.gameOver then
        -- 计算网格偏移量（与绘制函数中的计算保持一致）
        local windowHeight = love.graphics.getHeight()
        local gridOffsetX = 20
        local gridOffsetY = (windowHeight - GAME_HEIGHT) / 2
        
        -- 调整鼠标坐标，考虑网格偏移量
        local adjustedX = x - gridOffsetX
        local adjustedY = y - gridOffsetY
        
        local gridX = math.floor(adjustedX / TILE_SIZE) + 1
        local gridY = math.floor(adjustedY / TILE_SIZE) + 1
        
        if gridX >= 1 and gridX <= GRID_WIDTH and gridY >= 1 and gridY <= GRID_HEIGHT then
            if gameState.grid[gridY][gridX] > 0 then
                if gameState.selectedTile == nil then
                    -- 选择第一个方块
                    gameState.selectedTile = {x = gridX, y = gridY}
                elseif gameState.selectedTile.x == gridX and gameState.selectedTile.y == gridY then
                    -- 取消选择
                    gameState.selectedTile = nil
                else
                    -- 尝试连接两个方块
                    local tile1 = gameState.grid[gameState.selectedTile.y][gameState.selectedTile.x]
                    local tile2 = gameState.grid[gridY][gridX]
                    
                    if tile1 == tile2 and canConnect(gameState.selectedTile.x, gameState.selectedTile.y, gridX, gridY) then
                        -- 消除方块
                        gameState.grid[gameState.selectedTile.y][gameState.selectedTile.x] = 0
                        gameState.grid[gridY][gridX] = 0
                        gameState.score = gameState.score + 10
                        gameState.selectedTile = nil
                    else
                        -- 选择新的方块
                        gameState.selectedTile = {x = gridX, y = gridY}
                    end
                end
            end
        end
    end
end

-- 键盘输入处理
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "r" and gameState.gameOver then
        -- 重新开始游戏
        gameState.score = 0
        gameState.timeLeft = 300
        gameState.gameOver = false
        gameState.won = false
        gameState.selectedTile = nil
        initializeGrid()
        while not hasPossibleMoves() do
            initializeGrid()
        end
    end
end

-- 绘制游戏
function love.draw()
    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()
    
    -- 计算游戏网格居中位置
    local gridOffsetX = 20
    local gridOffsetY = (windowHeight - GAME_HEIGHT) / 2
    
    -- 绘制游戏区域背景
    love.graphics.setColor(0.15, 0.15, 0.15)
    love.graphics.rectangle("fill", gridOffsetX - 10, gridOffsetY - 10, GAME_WIDTH + 20, GAME_HEIGHT + 20)
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("line", gridOffsetX - 10, gridOffsetY - 10, GAME_WIDTH + 20, GAME_HEIGHT + 20)
    
    -- 绘制网格
    for y = 1, GRID_HEIGHT do
        for x = 1, GRID_WIDTH do
            local tileType = gameState.grid[y][x]
            local drawX = gridOffsetX + (x - 1) * TILE_SIZE
            local drawY = gridOffsetY + (y - 1) * TILE_SIZE
            
            if tileType > 0 then
                -- 绘制方块阴影效果
                love.graphics.setColor(0, 0, 0, 0.3)
                love.graphics.rectangle("fill", drawX + 4, drawY + 4, TILE_SIZE - 4, TILE_SIZE - 4)
                
                -- 绘制方块
                love.graphics.setColor(colors[tileType])
                love.graphics.rectangle("fill", drawX + 2, drawY + 2, TILE_SIZE - 4, TILE_SIZE - 4)
                
                -- 绘制方块高光效果
                love.graphics.setColor(1, 1, 1, 0.3)
                love.graphics.rectangle("fill", drawX + 2, drawY + 2, TILE_SIZE - 4, 8)
                
                -- 绘制边框
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.rectangle("line", drawX + 2, drawY + 2, TILE_SIZE - 4, TILE_SIZE - 4)
                
                -- 绘制选中效果
                if gameState.selectedTile and gameState.selectedTile.x == x and gameState.selectedTile.y == y then
                    love.graphics.setColor(1, 1, 0)
                    love.graphics.setLineWidth(4)
                    love.graphics.rectangle("line", drawX, drawY, TILE_SIZE, TILE_SIZE)
                    love.graphics.setLineWidth(1)
                    
                    -- 选中发光效果
                    love.graphics.setColor(1, 1, 0, 0.3)
                    love.graphics.rectangle("fill", drawX - 2, drawY - 2, TILE_SIZE + 4, TILE_SIZE + 4)
                end
            else
                -- 绘制空格子
                love.graphics.setColor(0.25, 0.25, 0.25)
                love.graphics.rectangle("line", drawX + 2, drawY + 2, TILE_SIZE - 4, TILE_SIZE - 4)
            end
        end
    end
    
    -- 右侧UI面板
    local panelX = gridOffsetX + GAME_WIDTH + 30
    local panelY = gridOffsetY
    local panelWidth = 180
    local panelHeight = 200
    
    -- 绘制UI面板背景
    love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 10, 10)
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight, 10, 10)
    love.graphics.setLineWidth(1)
    
    -- 绘制UI标题
    love.graphics.setColor(0.8, 0.9, 1)
    love.graphics.print("游戏信息", panelX + 15, panelY + 15, 0, 1.3)
    
    -- 绘制分数
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("分数:", panelX + 15, panelY + 45, 0, 1.2)
    love.graphics.setColor(0.4, 1, 0.4)
    love.graphics.print(gameState.score, panelX + 80, panelY + 45, 0, 1.4)
    
    -- 绘制时间
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("时间:", panelX + 15, panelY + 75, 0, 1.2)
    local timeColor = gameState.timeLeft < 60 and {1, 0.3, 0.3} or {0.4, 0.8, 1}
    love.graphics.setColor(timeColor)
    love.graphics.print(math.ceil(gameState.timeLeft) .. "s", panelX + 80, panelY + 75, 0, 1.4)
    
    -- 绘制操作说明
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("操作说明:", panelX + 15, panelY + 110, 0, 1.1)
    love.graphics.print("• 点击相同方块消除", panelX + 15, panelY + 130, 0, 0.9)
    love.graphics.print("• ESC: 退出游戏", panelX + 15, panelY + 150, 0, 0.9)
    love.graphics.print("• R: 重新开始", panelX + 15, panelY + 170, 0, 0.9)
    
    -- 游戏结束界面
    if gameState.gameOver then
        -- 半透明遮罩
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)
        
        -- 结束界面背景
        local dialogWidth = 300
        local dialogHeight = 200
        local dialogX = (windowWidth - dialogWidth) / 2
        local dialogY = (windowHeight - dialogHeight) / 2
        
        love.graphics.setColor(0.2, 0.2, 0.3, 0.95)
        love.graphics.rectangle("fill", dialogX, dialogY, dialogWidth, dialogHeight, 15, 15)
        love.graphics.setColor(0.6, 0.6, 0.7)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", dialogX, dialogY, dialogWidth, dialogHeight, 15, 15)
        love.graphics.setLineWidth(1)
        
        -- 结束消息
        local message = gameState.won and "🎉 恭喜获胜！" or "⏰ 游戏结束"
        local messageColor = gameState.won and {0.4, 1, 0.4} or {1, 0.6, 0.4}
        love.graphics.setColor(messageColor)
        love.graphics.print(message, dialogX + 80, dialogY + 30, 0, 1.8)
        
        -- 最终分数
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("最终分数: " .. gameState.score, dialogX + 90, dialogY + 80, 0, 1.4)
        
        -- 操作提示
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("按 R 重新开始", dialogX + 95, dialogY + 120, 0, 1.2)
        love.graphics.print("按 ESC 退出", dialogX + 105, dialogY + 150, 0, 1.2)
    end
end
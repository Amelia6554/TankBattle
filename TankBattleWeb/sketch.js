// ============================================================
// ZMIENNE GLOBALNE
// ============================================================

// --- Efekty -------------------------------------------------
let shakeAmount = 0;

// --- Stan gry -----------------------------------------------
let p = null;
let lastTime = 0;
let r;
let enemies = [];
let numberOfEnemies;
const GameStatus = {
    MENU: 0,
    PLAY: 1,
    GAMEOVER: 2,
    WIN: 3,
    PAUSE: 4,
    TUTORIAL: 5
};
let gameState = GameStatus.MENU;
let previousState = GameStatus.MENU;


// --- Tutorial -----------------------------------------------
let tutorialStep = 0;
let initialWallCount = 0;
let tutorialCols = 15;

// --- Efekty wizualne ----------------------------------------
let explosions = [];
let sparks = [];

// --- System powiadomień -------------------------------------
let notificationText = "";
let notificationTime = -5000;
let displayDuration = 2000;

// --- Struktura mapy -----------------------------------------
let desiredCols = 25;
let tileSize;
let cols, rows;
let gameMap = [];
let tileHP = [];
let maxTileHP = 100;

// ============================================================
// FUNKCJE P5.JS
// ============================================================

function setup() {
    createCanvas(windowWidth, windowHeight);
    
    calculateTilesize(tutorialCols);
    
    p = new Player(width/2, height/2, 200, 500, 'player');
    
    generateMap();
    numberOfEnemies = int(desiredCols * 0.1);
    
}

function windowResized() {
    resizeCanvas(windowWidth, windowHeight);
    if (p) {
        p.x = width / 2;
        p.y = height / 2;
    }
    calculateTilesize(tutorialCols);
}

function calculateTilesize(desiredCols) {
    if (width > 0) {
        tileSize = width / desiredCols;
        cols = desiredCols;
        rows = Math.ceil(height / tileSize);
    } else {
        tileSize = 40;
        cols = desiredCols;
        rows = 20;
    }
}

function draw() {    
    if (gameState === GameStatus.MENU) {
        drawMenu();
        return;
    }
    
    if (gameState === GameStatus.TUTORIAL) {
        updateTutorialLogic();
        drawTutorialGame();
        return;
    }
    
    drawGameVisuals();
    
    if (gameState === GameStatus.PLAY) {
        let currentTime = millis() / 1000.0;
        let deltaTime = currentTime - lastTime;
        lastTime = currentTime;
        
        if (deltaTime > 0.1) deltaTime = 0.016;
        
        updateGameLogic(deltaTime);
        checkWinLose();
    } else if (gameState === GameStatus.GAMEOVER) {
        gameOver();
    } else if (gameState === GameStatus.WIN) {
        Win();
    } else if (gameState === GameStatus.PAUSE) {
        drawPauseMenu();
    }
    
    drawNotification();
}

// ============================================================
// LOGIKA GRY
// ============================================================

function updateGameLogic(deltaTime) {
    p.update(deltaTime);
    p.updateMissles(deltaTime);
    
    for (let ex of explosions) {
        ex.update(deltaTime);
    }
    
    for (let s of sparks) {
        s.update(deltaTime);
    }
    
    for (let i = enemies.length - 1; i >= 0; i--) {
        let e = enemies[i];
        
        e.update(deltaTime);
        e.updateMissles(deltaTime);
        
        if (isHit(e, p.missles)) {
            explosions.push(new Explosion(e.x, e.y));
            if (!e.subtractHP(10)) {
                shakeAmount = 15;
                enemies.splice(i, 1);
            }
        }
        
        if (isHit(p, e.missles)) {
            explosions.push(new Explosion(p.x, p.y));
            if (!p.subtractHP(10)) {
                shakeAmount = 30;
                gameState = GameStatus.GAMEOVER;
            } else {
                shakeAmount = 5;
            }
        }
    }
}

function checkWinLose() {
    if (enemies.length === 0) {
        gameState = GameStatus.WIN;
    }
}

function resetGame() {
    // 1. Ustalenie liczby kolumn zależnie od tego czy to tutorial czy gra
    let currentCols = (gameState === GameStatus.TUTORIAL) ? tutorialCols : desiredCols;
    
    // 2. Przeliczenie rozmiaru kafelka (bardzo ważne przed stworzeniem gracza!)
    calculateTilesize(currentCols);
    
    // 3. Czyszczenie stanów
    keysPressed.clear();
    tutorialStep = 0;
    enemies = [];
    explosions = [];
    sparks = [];
    
    // 4. Stworzenie gracza (teraz weźmie nową wartość tileSize do swojego rozmiaru)
    p = new Player(width/2, height/2, 200, 500, 'player');
    
    // 5. Budowa świata
    generateMap();
    
    if (gameState === GameStatus.PLAY) {
        numberOfEnemies = int(desiredCols * 0.1);
        generateEnemies(numberOfEnemies);
    }
    
    lastTime = millis() / 1000.0;
}

// ============================================================
// GENEROWANIE ŚWIATA
// ============================================================

function generateEnemies(ratio) {
    enemies = [];
    for (let i = 0; i < ratio; i++) {
        enemies.push(new Enemy(0, 0, 50, 100, 'enemy'));
    }
    
    // Inicjalizuj pozycje
    for (let enemy of enemies) {
        if (enemy.initPosition) {
            enemy.initPosition();
        }
    }
}

function generateMap() {
    gameMap = Array(cols).fill().map(() => Array(rows).fill(0));
    tileHP = Array(cols).fill().map(() => Array(rows).fill(0));
    
    if (gameState === GameStatus.TUTORIAL) {
        for (let x = 0; x < cols; x++) {
            for (let y = 0; y < rows; y++) {
                if (x === 0 || y === 0 || x === cols-1 || y === rows-1) {
                    gameMap[x][y] = 1;
                    tileHP[x][y] = maxTileHP;
                }
            }
        }
        
        let midX = int(cols / 2) + 3;
        let midY = int(rows / 2);
        for (let i = -1; i < 2; i++) {
            gameMap[midX][midY + i] = 1;
            tileHP[midX][midY + i] = maxTileHP;
        }
    } else {
        for (let x = 0; x < cols; x++) {
            for (let y = 0; y < rows; y++) {
                if (x === 0 || y === 0 || x === cols-1 || y === rows-1) {
                    gameMap[x][y] = 1;
                    tileHP[x][y] = maxTileHP;
                } else {
                    if (random(1) < 0.15) {
                        gameMap[x][y] = 1;
                        tileHP[x][y] = maxTileHP;
                    }
                }
            }
        }
    }
    
    let px = int(p.x / tileSize);
    let py = int(p.y / tileSize);
    for (let dx = -1; dx <= 1; dx++) {
        for (let dy = -1; dy <= 1; dy++) {
            if (px + dx >= 0 && px + dx < cols && py + dy >= 0 && py + dy < rows) {
                gameMap[px + dx][py + dy] = 0;
                tileHP[px + dx][py + dy] = 0;
            }
        }
    }
}

// ============================================================
// SYSTEM KOLIZJI
// ============================================================

function collidesPlayer(x, y, playerWidth, playerHeight) {
    let halfW = playerWidth / 2;
    let halfH = playerHeight / 2;
    
    return collidesPoint(x - halfW, y - halfH) ||
           collidesPoint(x + halfW, y - halfH) ||
           collidesPoint(x - halfW, y + halfH) ||
           collidesPoint(x + halfW, y + halfH);
}

function collidesPoint(x, y) {
    let tx = int(x / tileSize);
    let ty = int(y / tileSize);
    
    if (tx < 0 || ty < 0 || tx >= cols || ty >= rows) return false;
    
    return gameMap[tx][ty] === 1;
}

function canSpawnTank(x, y, w, h) {
    let hw = w / 2;
    let hh = h / 2;
    
    return !collidesPoint(x - hw, y - hh) &&
           !collidesPoint(x + hw, y - hh) &&
           !collidesPoint(x - hw, y + hh) &&
           !collidesPoint(x + hw, y + hh);
}

function isHit(tank, missles) {
    for (let m of missles) {
        let d = dist(tank.x, tank.y, m.x, m.y);
        if (d < tank.heightTank/2 + m.h/2) {
            m.h = 0;
            m.w = 0;
            return true;
        }
    }
    return false;
}

// ============================================================
// RENDEROWANIE
// ============================================================

function drawGameVisuals() {
    push();
    
    if (shakeAmount > 0) {
        translate(random(-shakeAmount, shakeAmount), random(-shakeAmount, shakeAmount));
        shakeAmount *= 0.9;
        if (shakeAmount < 0.5) shakeAmount = 0;
    }
    
    drawMap();
    
    p.display(mouseX, mouseY);
    p.displayMissles();
    
    for (let e of enemies) {
        e.display(p.x, p.y);
        e.displayMissles();
    }
    
    for (let i = sparks.length - 1; i >= 0; i--) {
        let s = sparks[i];
        s.display();
        if (!s.alive) sparks.splice(i, 1);
    }
    
    for (let i = explosions.length - 1; i >= 0; i--) {
        let ex = explosions[i];
        ex.display();
        if (!ex.alive) explosions.splice(i, 1);
    }
    
    pop();
}

function drawMap() {
    for (let x = 0; x < cols; x++) {
        for (let y = 0; y < rows; y++) {
            let posX = x * tileSize;
            let posY = y * tileSize;
            
            drawTileGround(posX, posY, tileSize);
            
            if (gameMap[x][y] === 1) {
                let hp = tileHP[x][y];
                drawTileBox(posX, posY, tileSize, hp);
            }
        }
    }
}

// ============================================================
// TUTORIAL
// ============================================================

function drawTutorialGame() {
    drawGameVisuals();
    
    push();
    textAlign(CENTER);
    textSize(35);
    fill(0, 150);
    text(getTutorialText(), width/2 + 2, 102);
    fill(255, 255, 0);
    text(getTutorialText(), width/2, 100);
    pop();
}

function getTutorialText() {
    switch(tutorialStep) {
        case 0: return "Użyj klawiszy WASD, aby się poruszyć";
        case 1: return "Świetnie! Teraz celuj myszką i naciśnij LPM, aby strzelić";
        case 2: return "Zniszcz dowolną przeszkodę, aby przejść dalej";
        case 3: return "Brawo! Jesteś gotowy. Naciśnij SPACJĘ, aby zacząć prawdziwą bitwę!";
        default: return "";
    }
}

function updateTutorialLogic() {
    let currentTime = millis() / 1000.0;
    let deltaTime = currentTime - lastTime;
    lastTime = currentTime;
    
    p.update(deltaTime);
    p.updateMissles(deltaTime);
    
    for (let ex of explosions) {
        ex.update(deltaTime);
    }
    
    for (let s of sparks) {
        s.update(deltaTime);
    }

    let isMoving = keysPressed.has('w') || keysPressed.has('a') || 
                   keysPressed.has('s') || keysPressed.has('d') ||
                   keysPressed.has('arrowup') || keysPressed.has('arrowdown') ||
                   keysPressed.has('arrowleft') || keysPressed.has('arrowright');

    if (tutorialStep === 0 && isMoving) {
        tutorialStep = 1;
    } else if (tutorialStep === 1 && p.missles.length > 0) {
        tutorialStep = 2;
        initialWallCount = countWalls();
    } else if (tutorialStep === 2 && countWalls() < initialWallCount) {
        tutorialStep = 3;
    }
}

function countWalls() {
    let count = 0;
    for (let x = 0; x < cols; x++) {
        for (let y = 0; y < rows; y++) {
            if (gameMap[x][y] === 1) count++;
        }
    }
    return count;
}

// ============================================================
// INTERFEJS UŻYTKOWNIKA
// ============================================================

function drawMenu() {
    push();
    background(30);
    fill(0, 0, 0, 120);
    rect(0, 0, width, height);
    
    textAlign(CENTER, CENTER);
    
    let pulse = 1.0 + sin(frameCount * 0.08) * 0.06;
    push();
    translate(width/2, height/2 - 100);
    scale(pulse);
    fill(255, 80, 80);
    textSize(80);
    text("TANK BATTLE", 0, 0);
    pop();
    
    fill(200);
    textSize(20);
    text("Zniszcz wroga. Przetrwaj jak najdłużej.", width/2, height/2 - 30);
    
    // Tylko przycisk START
    let bx = width/2;
    let by = height/2 + 60;
    let hover = dist(mouseX, mouseY, bx, by) < 160 && abs(mouseY - by) < 30;
    
    fill(hover ? lerpColor(color(255, 80, 80), color(0), 0.25) : 90);
    rectMode(CENTER);
    rect(bx, by, 320, 55, 12);
    
    fill(255);
    textSize(26);
    text("START", bx, by - 4);
    
    fill(150);
    textSize(14);
    text("Sterowanie: WASD + MYSZ", width/2, height - 40);
    pop();
}

function drawPauseMenu() {
    push();
    fill(0, 0, 0, 180);
    rect(0, 0, width, height);
    
    textAlign(CENTER, CENTER);
    fill(0, 100, 255);
    textSize(70);
    text("PAUZA", width/2, height/2 - 120);
    
    // Dynamiczna lista etykiet
    let labels = ["WZNÓW"];
    if (previousState === GameStatus.PLAY) {
        labels.push("RESTART"); // Dodaj restart tylko w trybie PLAY
    }
    labels.push("MENU GŁÓWNE");
    
    for (let i = 0; i < labels.length; i++) {
        let bx = width/2;
        let by = height/2 - 20 + (i * 80);
        let hover = dist(mouseX, mouseY, bx, by) < 125 && abs(mouseY - by) < 25;
        
        fill(hover ? color(0, 80, 200) : 100);
        rectMode(CENTER);
        rect(bx, by, 250, 55, 10);
        
        fill(255);
        textSize(24);
        text(labels[i], bx, by - 5);
    }
    pop();
}

function gameOver() {
    drawEndScreen("PORAŻKA", color(255, 0, 0));
}

function Win() {
    drawEndScreen("ZWYCIĘSTWO", color(0, 255, 0));
}

function drawEndScreen(title, titleColor) {
    push();
    fill(0, 0, 0, 180);
    rect(0, 0, width, height);
    
    textAlign(CENTER, CENTER);
    let pulse = 1.0 + sin(frameCount * 0.1) * 0.05;
    push();
    translate(width/2, height/2 - 120);
    scale(pulse);
    fill(titleColor);
    textSize(70);
    text(title, 0, 0);
    pop();
    
    let labels = ["ZAGRAJ PONOWNIE", "MENU GŁÓWNE"];
    for (let i = 0; i < labels.length; i++) {
        let bx = width/2;
        let by = height/2 + 20 + (i * 80);
        let hover = dist(mouseX, mouseY, bx, by) < 150 && abs(mouseY - by) < 25;
        
        fill(hover ? lerpColor(titleColor, color(0), 0.4) : 100);
        rectMode(CENTER);
        rect(bx, by, 300, 55, 10);
        
        fill(255);
        textSize(24);
        text(labels[i], bx, by - 5);
    }
    pop();
}

function drawNotification() {
    let elapsed = millis() - notificationTime;
    
    if (elapsed < displayDuration) {
        push();
        let alpha = map(elapsed, 0, displayDuration, 255, 0);
        textAlign(CENTER);
        textSize(30);
        fill(255, 255, 0, alpha);
        text(notificationText, width/2, 60);
        pop();
    }
}

function showNotify(msg) {
    notificationText = msg;
    notificationTime = millis();
}

// ============================================================
// OBSŁUGA INPUTU
// ============================================================

function mousePressed() {
    if (gameState === GameStatus.MENU) {
        // Przycisk START
        if (mouseX > width/2 - 160 && mouseX < width/2 + 160 &&
            mouseY > height/2 + 60 - 27 && mouseY < height/2 + 60 + 27) {
            gameState = GameStatus.TUTORIAL;
            resetGame();
        }
    } 
    else if (gameState === GameStatus.GAMEOVER || gameState === GameStatus.WIN) {
        if (mouseX > width/2 - 150 && mouseX < width/2 + 150) {
            // Zagraj ponownie
            if (mouseY > height/2 + 20 - 27 && mouseY < height/2 + 20 + 27) {
                gameState = GameStatus.PLAY;
                resetGame();
                lastTime = millis() / 1000.0;
            }
            // Menu główne
            if (mouseY > height/2 + 100 - 27 && mouseY < height/2 + 100 + 27) {
                gameState = GameStatus.MENU;
            }
        }
    } 
    else if (gameState === GameStatus.PAUSE) {
    let bx = width/2;
    // Sprawdzamy pierwszy przycisk: WZNÓW (zawsze na górze)
    if (mouseX > bx - 125 && mouseX < bx + 125 && mouseY > height/2 - 20 - 27 && mouseY < height/2 - 20 + 27) {
        gameState = previousState;
        lastTime = millis() / 1000.0;
    }

    if (previousState === GameStatus.PLAY) {
        // Jeśli jest RESTART (środkowy przycisk)
        if (mouseX > bx - 125 && mouseX < bx + 125 && mouseY > height/2 + 60 - 27 && mouseY < height/2 + 60 + 27) {
            gameState = GameStatus.PLAY;
            resetGame();
        }
        // MENU GŁÓWNE (trzeci przycisk)
        if (mouseX > bx - 125 && mouseX < bx + 125 && mouseY > height/2 + 140 - 27 && mouseY < height/2 + 140 + 27) {
            gameState = GameStatus.MENU;
            resetGame();
        }
    } else {
        // Jeśli tutorial (brak restartu, MENU GŁÓWNE jest drugie)
        if (mouseX > bx - 125 && mouseX < bx + 125 && mouseY > height/2 + 60 - 27 && mouseY < height/2 + 60 + 27) {
            gameState = GameStatus.MENU;
            resetGame();
        }
    }
    }
    else if (gameState === GameStatus.PLAY || gameState === GameStatus.TUTORIAL) {
        p.shoot(mouseX, mouseY);
    }
}

function keyPressed() {
    if (key === 'q') {
        if (gameState === GameStatus.PLAY || gameState === GameStatus.TUTORIAL) {
            previousState = gameState;
            gameState = GameStatus.PAUSE;
        } else if (gameState === GameStatus.PAUSE) {
            gameState = previousState;
            lastTime = millis() / 1000.0;
        }
        return false; // Zapobiega domyślnej akcji przeglądarki
    }
    
    if ((key === 'r' || key === 'R') && gameState == GameStatus.PLAY) {
        resetGame();
        gameState = GameStatus.PLAY;
        lastTime = millis() / 1000.0;
    }
    
    if (gameState === GameStatus.TUTORIAL && tutorialStep === 3 && key === ' ') {
        gameState = GameStatus.PLAY;
        calculateTilesize(desiredCols);
        resetGame();
        lastTime = millis() / 1000.0;
    }
}

// --- Stan klawiszy ---
let keysPressed = new Set();

window.addEventListener('keydown', (e) => {
    keysPressed.add(e.key.toLowerCase());
});

window.addEventListener('keyup', (e) => {
    keysPressed.delete(e.key.toLowerCase());
});


// ============================================================
// Funkcje do rysowania kształtów zamiast SVG
// ============================================================

function drawMissilePlayer(x, y, w, h, angle) {
    let s = 0.7; // Skala pocisku (70% oryginału)
    let sw = w * s;
    let sh = h * s;

    push();
    translate(x, y);
    rotate(angle);
    
    rectMode(CENTER);
    stroke(0);
    strokeWeight(2 * s);
    strokeJoin(ROUND);

    // 1. Płomień
    noStroke();
    fill(255, 69, 0); 
    triangle(-sw/4, sh/2, sw/4, sh/2, 0, sh*0.9);
    fill(255, 215, 0); 
    triangle(-sw/8, sh/2, sw/8, sh/2, 0, sh*0.75);

    // 2. Silnik / Dysza
    stroke(0);
    fill(28, 28, 28);
    rect(0, sh/2.5, sw/2, sh/6);

    // 3. Korpus
    fill(85, 107, 47); 
    rect(0, 0, sw/1.5, sh/1.5);

    // 4. Głowica
    fill(218, 165, 32); 
    triangle(-sw/3, -sh/3, sw/3, -sh/3, 0, -sh/1.5);
    
    pop();
}

function drawMissileEnemy(x, y, w, h, angle) {
    let s = 0.7; // Skala pocisku
    let sw = w * s;
    let sh = h * s;

    push();
    translate(x, y);
    rotate(angle);
    
    rectMode(CENTER);
    stroke(0);
    strokeWeight(2 * s);
    strokeJoin(ROUND);

    // 1. Płomień
    noStroke();
    fill(255, 69, 0);
    triangle(-sw/4, sh/2, sw/4, sh/2, 0, sh*0.9);
    fill(255, 215, 0);
    triangle(-sw/8, sh/2, sw/8, sh/2, 0, sh*0.75);

    // 2. Silnik
    stroke(0);
    fill(51, 51, 51);
    rect(0, sh/2.5, sw/2, sh/6);

    // 3. Korpus 
    fill(136, 136, 136);
    rect(0, 0, sw/1.5, sh/1.5);

    // 4. Głowica
    fill(204, 0, 0);
    triangle(-sw/3, -sh/3, sw/3, -sh/3, 0, -sh/1.5);
    
    pop();
}

function drawTankPlayerBottom(x, y, w, h, angle, hp) {
    push();
    translate(x, y);
    rotate(angle); // Orientacja pionowa pod SVG
    
    rectMode(CENTER);
    stroke(0);
    strokeWeight(2);

    // 1. Gąsienice (szare - #606060)
    fill(96, 96, 96);
    rect(-w/2.5, 0, w/4, h, 2); // Lewa
    rect(w/2.5, 0, w/4, h, 2);  // Prawa

    // Prążki na gąsienicach (z SVG)
    strokeWeight(1.5);
    for (let i = -h/2 + 5; i < h/2; i += 10) {
        line(-w/2.5 - w/8, i, -w/2.5 + w/8, i);
        line(w/2.5 - w/8, i, w/2.5 + w/8, i);
    }

    // 2. Korpus (ciemnozielony wojskowy - #556B2F)
    strokeWeight(2);
    fill(85, 107, 47);
    rect(0, 0, w/1.8, h * 0.8);

    // 3. Detale z tyłu (trzy kwadraciki z SVG)
    noFill();
    rect(-w/6, h/3, w/10, h/10);
    rect(0, h/3, w/10, h/10);
    rect(w/6, h/3, w/10, h/10);

    // 4. Efekty uszkodzeń (Dym i płomień z tyłu - layer-damage)
    if (hp < 40) {
        noStroke();
        // Kłęby dymu (różne odcienie szarości)
        fill(17, 17, 17, 180); circle(0, h/4, w/2);
        fill(51, 51, 51, 150); circle(w/4, h/5, w/2.5);
        fill(34, 34, 34, 130); circle(-w/4, h/5, w/3);
        
        // Płomień (OrangeRed i Gold)
        fill(255, 69, 0);
        beginShape();
        vertex(-w/4, h/2.5); vertex(-w/6, h/1.2); vertex(0, h/2.5);
        vertex(w/8, h/1.3); vertex(w/4, h/2.5);
        endShape(CLOSE);
        
        fill(255, 215, 0);
        triangle(-w/8, h/2.5, 0, h/1.5, w/8, h/2.5);
    }

    pop();
}

function drawTankPlayerGun(x, y, w, h, angle, hp) {
    // --- SKALOWANIE ---
    let s = 0.8; // Zmień tę wartość, aby dostosować wielkość (np. 0.5 to połowa)
    let sw = w * s;
    let sh = h * s;
    // ------------------

    push();
    translate(x, y);
    rotate(angle+ HALF_PI);
    
    rectMode(CENTER);
    stroke(0);
    strokeWeight(2 * s); // Skalujemy też grubość obrysu, żeby nie był za ciężki

    // 1. Lufa (ciemna zieleń - #3E4C24)
    fill(62, 76, 36);
    rect(0, -sh/2, sw/8, sh); // Główna część
    rect(0, -sh, sw/5, sh/5);  // Końcówka lufy

    // 2. Wieżyczka (Kształt "diamentowy" - #6B8E23)
    fill(107, 142, 35);
    beginShape();
    vertex(-sw/4, sh/4);   // Lewy dół
    vertex(-sw/4, -sh/8);  // Lewy bok
    vertex(-sw/8, -sh/3);  // Lewa góra
    vertex(sw/8, -sh/3);   // Prawa góra
    vertex(sw/4, -sh/8);   // Prawy bok
    vertex(sw/4, sh/4);    // Prawy dół
    vertex(0, sh/2.5);     // Tył
    endShape(CLOSE);

    // 3. Włazy (detale - #486018)
    fill(72, 96, 24);
    rect(-sw/8, 0, sw/12, sh/8);
    rect(sw/8, 0, sw/10, sh/6);

    // 4. Uszkodzenia wieżyczki
    if (hp < 60) {
        stroke(0, 180);
        line(-sw/6, -sh/10, 0, 0); 
        line(0, 0, sw/8, -sh/20);
        
        noStroke();
        fill(0, 80);
        circle(sw/6, 0, sw/5); 
    }

    pop();
}

function drawTankEnemyBottom(x, y, w, h, angle, hp) {
    push();
    translate(x, y);
    rotate(angle); // Dostosowanie do orientacji pionowej SVG
    
    rectMode(CENTER);
    stroke(0);
    strokeWeight(2);

    // 1. Gąsienice (szare - #606060)
    fill(96, 96, 96);
    rect(-w/2.5, 0, w/4, h, 2); // Lewa
    rect(w/2.5, 0, w/4, h, 2);  // Prawa

    // Detale gąsienic (poziome linie)
    strokeWeight(1);
    for (let i = -h/2 + 5; i < h/2; i += 10) {
        line(-w/2.5 - w/8, i, -w/2.5 + w/8, i);
        line(w/2.5 - w/8, i, w/2.5 + w/8, i);
    }

    // 2. Korpus (czerwony - #b30000)
    strokeWeight(2);
    fill(179, 0, 0);
    rect(0, 0, w/1.8, h * 0.8);

    // 3. Detale z tyłu (małe kwadraty z SVG)
    noFill();
    rect(-w/6, h/3, w/10, h/10);
    rect(0, h/3, w/10, h/10);
    rect(w/6, h/3, w/10, h/10);

    // 4. Efekty uszkodzeń (Dym i ogień z SVG)
    if (hp < 50) {
        noStroke();
        // Ciemny dym
        fill(34, 34, 34, 150);
        circle(0, 0, w/2);
        circle(w/4, -h/6, w/3);
        
        // Ogień z tyłu
        fill(255, 69, 0); // OrangeRed
        beginShape();
        vertex(-w/4, h/2.5);
        vertex(0, h/1.5);
        vertex(w/4, h/2.5);
        vertex(w/8, h/2.8);
        vertex(0, h/2.2);
        vertex(-w/8, h/2.8);
        endShape(CLOSE);
    }

    pop();
}

function drawTankEnemyGun(x, y, w, h, angle, hp) {
    // --- SKALOWANIE ---
    let s = 0.8; // Zmień na np. 0.6 dla jeszcze mniejszego efektu
    let sw = w * s;
    let sh = h * s;
    // ------------------

    push();
    translate(x, y);
    rotate(angle + HALF_PI);
    
    rectMode(CENTER);
    stroke(0);
    strokeWeight(2 * s); // Skalujemy grubość linii obrysu

    // 1. Lufa (czerwona z ciemniejszym końcem)
    fill(204, 0, 0); 
    rect(0, -sh/2, sw/8, sh); // Główna lufa
    rect(0, -sh, sw/5, sh/5);  // Zakończenie lufy

    // 2. Wieżyczka (Kanciasty kształt)
    fill(255, 26, 26); 
    beginShape();
    vertex(-sw/4, sh/4);   // Lewy dół
    vertex(-sw/4, -sh/8);  // Lewy bok
    vertex(-sw/8, -sh/3);  // Lewa góra
    vertex(sw/8, -sh/3);   // Prawa góra
    vertex(sw/4, -sh/8);   // Prawy bok
    vertex(sw/4, sh/4);    // Prawy dół
    vertex(0, sh/2.5);     // Tył (szpic)
    endShape(CLOSE);

    // 3. Włazy/Detale na górze
    fill(230, 0, 0); 
    rect(-sw/8, 0, sw/12, sh/8);
    rect(sw/8, 0, sw/10, sh/6);

    // 4. Uszkodzenia wieżyczki
    if (hp < 30) {
        stroke(0);
        line(-sw/6, -sh/6, 0, 0);
        line(0, 0, sw/6, -sh/10);
        noStroke();
        fill(0, 100);
        circle(sw/8, sh/8, sw/4);
    }

    pop();
}

function drawExplosion(x, y, size) {
    push();
    translate(x, y);
    
    // Centralna kula ognia (pomarańczowo-żółta)
    for (let i = 0; i < 5; i++) {
        let r = size * 0.8 * (1 - i * 0.15);
        let alpha = 255 - i * 50;
        let c = color(255, 165 - i * 20, 0, alpha);
        fill(c);
        noStroke();
        ellipse(0, 0, r, r);
    }
    
    // Iskry
    for (let i = 0; i < 12; i++) {
        let a = random(TWO_PI);
        let d = random(size * 0.3, size * 0.8);
        let sparkX = cos(a) * d;
        let sparkY = sin(a) * d;
        let sparkSize = random(3, 8);
        
        fill(255, random(200, 255), 0);
        ellipse(sparkX, sparkY, sparkSize, sparkSize);
    }
    
    pop();
}

function drawSparks(x, y, size) {
    push();
    translate(x, y);
    
    // Kilka małych żółtych kółek
    for (let i = 0; i < 4; i++) {
        let offsetX = random(-size/2, size/2);
        let offsetY = random(-size/2, size/2);
        let sparkSize = random(2, 6);
        
        fill(255, 255, 0, random(150, 255));
        noStroke();
        ellipse(offsetX, offsetY, sparkSize, sparkSize);
    }
    
    pop();
}

function drawTileGround(x, y, size) {
    push();
    translate(x, y);
    noStroke();
    
    // Tło (piaskowy/skalisty)
    fill(139, 139, 122); // #8B8B7A
    rect(0, 0, size, size);
    
    // Plamy terenu
    fill(95, 95, 80, 150); // #5F5F50 z przezroczystością
    ellipse(size * 0.25, size * 0.2, size * 0.3, size * 0.2);
    ellipse(size * 0.75, size * 0.75, size * 0.3, size * 0.2);
    
    // Małe kamienie
    fill(62, 62, 54); // #3E3E36
    circle(size * 0.8, size * 0.2, size * 0.06);
    circle(size * 0.2, size * 0.8, size * 0.04);
    
    // Delikatne rysy/linie
    stroke(74, 74, 64, 80); // #4A4A40
    strokeWeight(1);
    line(0, size * 0.1, size * 0.2, 0);
    line(size * 0.8, size, size, size * 0.9);
    pop();
}   

function drawTileBox(x, y, size, hp) {
    push();
    translate(x, y);
    rectMode(CORNER);
    strokeJoin(ROUND);

    if (hp > 75) {
        // --- STAN: IDEALNY (layer-fresh) ---
        fill(77, 89, 102); // #4d5966
        stroke(0);
        strokeWeight(size * 0.04);
        rect(2, 2, size - 4, size - 4);
        
        // Przekątne (X)
        stroke(0, 200); 
        line(size * 0.1, size * 0.1, size * 0.9, size * 0.9);
        line(size * 0.9, size * 0.1, size * 0.1, size * 0.9);
        
        // Nity w rogach
        noStroke();
        fill(47, 79, 79);
        circle(size * 0.1, size * 0.1, size * 0.07);
        circle(size * 0.9, size * 0.1, size * 0.07);
        circle(size * 0.1, size * 0.9, size * 0.07);
        circle(size * 0.9, size * 0.9, size * 0.07);

    } else if (hp > 40) {
        // --- STAN: LEKKO USZKODZONY (layer-damaged-light) ---
        fill(77, 89, 102);
        stroke(0);
        strokeWeight(2);
        quad(4, 4, size-4, 6, size-6, size-6, 6, size-4); // Lekko krzywy kształt
        
        // Pęknięcia
        stroke(0, 150);
        line(size*0.3, size*0.4, size*0.2, size*0.3);
        line(size*0.3, size*0.4, size*0.4, size*0.35);
        
        // Odpadający nit
        fill(26, 26, 26);
        circle(size * 0.2, size * 0.2, size * 0.06);

    } else if (hp > 0) {
        // --- STAN: MOCNO USZKODZONY (layer-damaged-heavy) ---
        fill(54, 61, 69); // #363d45
        stroke(0);
        strokeWeight(2);
        // Nieregularny wielokąt
        beginShape();
        vertex(size*0.12, size*0.15);
        vertex(size*0.88, size*0.08);
        vertex(size*0.92, size*0.45);
        vertex(size*0.8, size*0.88);
        vertex(size*0.45, size*0.92);
        vertex(size*0.08, size*0.82);
        endShape(CLOSE);
        
        // Dziura w środku
        fill(26, 26, 26);
        ellipse(size*0.5, size*0.5, size*0.2, size*0.2);

    } else {
        // --- STAN: ZNISZCZONY (layer-ground / wrak) ---
        noStroke();
        fill(43, 36, 31); // #2b241f
        ellipse(size*0.5, size*0.55, size*0.9, size*0.7);
        fill(59, 50, 44); // #3b322c
        ellipse(size*0.48, size*0.52, size*0.8, size*0.6);
    }
    
    pop();
}
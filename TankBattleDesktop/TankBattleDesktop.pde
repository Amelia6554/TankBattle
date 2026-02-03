import processing.sound.*;
import javax.swing.JFileChooser;
import javax.swing.JOptionPane;
import javax.swing.filechooser.FileNameExtensionFilter;

// ============================================================
// ZASOBY I ZMIENNE GLOBALNE
// ============================================================

// --- Dźwięki ------------------------------------------------
SoundFile file;
SoundFile death;
SoundFile takeDamage;
SoundFile playerDeath;
SoundFile bgMusic;
SoundFile win;
float shakeAmount = 0;

// --- Stan gry -----------------------------------------------
boolean w, a, s, d;
Player p;
Enemy e;
float lastTime = 0;
int r;
ArrayList<Enemy> enemies;
int numberOfEnemies;
enum GameStatus {
  MENU, PLAY, GAMEOVER, WIN, PAUSE, TUTORIAL
}

GameStatus gameState = GameStatus.MENU;
GameStatus previousState = GameStatus.MENU;

// --- tutorial -----------------------------------------------
int tutorialStep = 0; 
int initialWallCount = 0; // Pomoże nam sprawdzić, czy gracz zniszczył ścianę
int tutorialCols = 15;

// --- Efekty wizualne ----------------------------------------
ArrayList<Explosion> explosions = new ArrayList<Explosion>();
PShape explosionImg;
ArrayList<Spark> sparks = new ArrayList<Spark>();
PShape sparkImg;

// --- System powiadomień -------------------------------------
String notificationText = "";
int notificationTime = -5000;
int displayDuration = 2000;

// --- Struktura mapy -----------------------------------------
int desiredCols = 40;
float tileSize;
int cols, rows;
int[][] map;
float[][] tileHP;
float maxTileHP = 100;

// --- Grafiki czołgów i pocisków ----------------------------
PShape missleEnemyImg;
PShape misslePlayerImg;
PShape tankPlayerBottomImg;
PShape tankPlayerGunImg;
PShape tankEnemyBottomImg;
PShape tankEnemyGunImg;

// --- Grafiki terenu -----------------------------------------
PShape tileBox;
PShape tileBoxBroken;
PShape tileGround;
PShape layerFresh, layerLight, layerHeavy, layerGround;


// ============================================================
// INICJALIZACJA
// ============================================================

void setup(){
  fullScreen(); 
  
  // Ładowanie grafik czołgów i pocisków
  missleEnemyImg = loadShape("img/missileEnemy.svg");
  misslePlayerImg = loadShape("img/missilePlayer.svg");
  explosionImg = loadShape("img/explosion.svg");
  sparkImg = loadShape("img/sparks.svg");
  tankPlayerBottomImg = loadShape("img/tankPlayerBottom.svg");
  tankPlayerGunImg = loadShape("img/tankPlayerGun.svg");
  tankEnemyBottomImg = loadShape("img/tankEnemyBottom.svg");
  tankEnemyGunImg = loadShape("img/tankEnemyGun.svg");

  // Ładowanie grafik terenu
  tileBoxBroken = loadShape("img/tileBoxBroken.svg");
  tileGround = loadShape("img/tileGround.svg");

  // Ładowanie dźwięków
  file = new SoundFile(this, "audio/shoot.mp3");
  death = new SoundFile(this, "audio/death.mp3");
  takeDamage = new SoundFile(this, "audio/takeDamage.mp3");
  playerDeath = new SoundFile(this, "audio/playerDeath.mp3");
  win = new SoundFile(this, "audio/win.mp3");

  // Muzyka w tle
  bgMusic = new SoundFile(this, "audio/tank-battle.mp3");
  bgMusic.loop();
  bgMusic.amp(0.2); 

  // Przygotowanie warstw uszkodzeń ścian
  PShape fullBox = loadShape("img/tileBoxBroken.svg");
  layerFresh = fullBox.getChild("layer-fresh");
  layerLight = fullBox.getChild("layer-damaged-light");
  layerHeavy = fullBox.getChild("layer-damaged-heavy");
  layerGround = fullBox.getChild("layer-ground");
  
  tileHP = new float[cols][rows];

  // Inicjalizacja kontrolek
  w = false;
  a = false;
  s = false;
  d = false;

  calculateTilesize(tutorialCols);
  
  // Utworzenie gracza i generacja świata
  p = new Player(tankPlayerBottomImg, tankPlayerGunImg, misslePlayerImg);
  r = 0;

  numberOfEnemies = int(desiredCols * 0.2);
  enemies = new ArrayList<Enemy>(); 
  gameState = GameStatus.MENU;
}

void calculateTilesize(int desiredCols){
    // Kalkulacja rozmiaru kafelków
  tileSize = width / (float)desiredCols; 
  cols = desiredCols;
  rows = ceil(height / tileSize);
}


// ============================================================
// GŁÓWNA PĘTLA GRY
// ============================================================

void draw() {
  if (gameState == GameStatus.MENU) {
    drawMenu();
    return;
  }
  
  if (gameState == GameStatus.TUTORIAL) {
    updateTutorialLogic(); // Nowa funkcja logiki
    drawTutorialGame();   // Nowa funkcja rysowania
    return;
  }

  drawGameVisuals(); 

  if (gameState == GameStatus.PLAY) {
    float currentTime = millis() / 1000.0;
    float deltaTime = currentTime - lastTime;
    lastTime = currentTime;
    
    if (deltaTime > 0.1) deltaTime = 0.016; 

    updateGameLogic(deltaTime);
    checkWinLose();
    
  } else if (gameState == GameStatus.GAMEOVER) {
    gameOver();
  } else if (gameState == GameStatus.WIN) {
    Win();
  } else if (gameState == GameStatus.PAUSE) {
    drawPauseMenu();
  }

  drawNotification();
}


// ============================================================
// LOGIKA GRY
// ============================================================

void updateGameLogic(float deltaTime) {
  p.update(deltaTime);
  p.updateMissles(deltaTime);

  for (Explosion ex : explosions) {
    ex.update(deltaTime);
  }

  for(Spark s: sparks){
    s.update(deltaTime);
  }
  
  // Pętla po wrogach od końca, żeby bezpiecznie usuwać elementy
  for (int i = enemies.size() - 1; i >= 0; i--) {
    Enemy e = enemies.get(i);
    
    e.update(deltaTime);
    e.updateMissles(deltaTime);

    if (isHit(e, p.missles)) {
      explosions.add(new Explosion(e.x, e.y, explosionImg));
      if (!e.subtractHP(10)) {
        shakeAmount = 15;
        enemies.remove(i);
        death.play();
      }
    }

    if(isHit(p, e.missles)){
      explosions.add(new Explosion(p.x, p.y, explosionImg));
      if (!p.subtractHP(10)) {
        shakeAmount = 30;
        gameState = GameStatus.GAMEOVER;
        playerDeath.play();
      } else {
        shakeAmount = 5;
        takeDamage.play();
      }
    }
  }
}

void checkWinLose() {
  if (enemies.size() == 0) {
      gameState = GameStatus.WIN;
      win.play();
  }
}

void resetGame() {
  w = false; a = false; s = false; d = false;
  p = new Player(tankPlayerBottomImg, tankPlayerGunImg, misslePlayerImg);
  generateMap();
  numberOfEnemies = int(desiredCols * 0.3);
  generatEnemies(numberOfEnemies);
  loop(); 
}


// ============================================================
// GENEROWANIE ŚWIATA
// ============================================================

void generatEnemies(int ratio){
  enemies = new ArrayList<Enemy>();
  for (int i=0; i<ratio; i++){
    enemies.add(new Enemy(tankEnemyBottomImg, tankEnemyGunImg, missleEnemyImg));
  }
}

void generateMap() {
  map = new int[cols][rows];
  tileHP = new float[cols][rows];

if (gameState == GameStatus.TUTORIAL) {
    // --- MAPA TUTORIALOWA ---
    // Generujemy tylko obramowanie (ściany zewnętrzne)
    for (int x = 0; x < cols; x++) {
      for (int y = 0; y < rows; y++) {
        if (x == 0 || y == 0 || x == cols-1 || y == rows-1) {
          map[x][y] = 1;
          tileHP[x][y] = maxTileHP;
        } else {
          map[x][y] = 0;
          tileHP[x][y] = 0;
        }
      }
    }
    // Stawiamy JEDEN blok na środku jako cel ćwiczebny
    int midX = cols / 2 + 3;
    int midY = rows / 2;
    for (int i=-1; i < 2; i ++){
      map[midX][midY+i] = 1;
      tileHP[midX][midY+i] = maxTileHP;
    }

    
  } else {
    // --- STANDARDOWA MAPA GRY ---
    for (int x = 0; x < cols; x++) {
      for (int y = 0; y < rows; y++) {
        if (x == 0 || y == 0 || x == cols-1 || y == rows-1) {
          map[x][y] = 1;
          tileHP[x][y] = maxTileHP;
        } else {
          if (random(1) < 0.15) {
            map[x][y] = 1;
            tileHP[x][y] = maxTileHP;
          } else {
            map[x][y] = 0;
            tileHP[x][y] = 0;
          }
        }
      }
    }
  }

  // Wyczyszczenie startera gracza z przeszkód
  int px = int(p.x / tileSize);
  int py = int(p.y / tileSize);
  for (int dx = -1; dx <= 1; dx++) {
    for (int dy = -1; dy <= 1; dy++) {
      if (px + dx >= 0 && px + dx < cols && py + dy >= 0 && py + dy < rows) {
        map[px + dx][py + dy] = 0;
        tileHP[px + dx][py + dy] = 0;
      }
    }
  }
}


// ============================================================
// SYSTEM KOLIZJI
// ============================================================

boolean collidesPlayer(float x, float y, float PlayerWidth, float PlayerHeight){
  float halfW = PlayerWidth / 2;
  float halfH = PlayerHeight / 2;

  return
    collidesPoint(x - halfW, y - halfH) ||
    collidesPoint(x + halfW, y - halfH) ||
    collidesPoint(x - halfW, y + halfH) ||
    collidesPoint(x + halfW, y + halfH);
}

boolean collidesPoint(float x, float y){
  int tx = int(x / tileSize);
  int ty = int(y / tileSize);
  
  // Pozwól na teleportację przez krawędzie ekranu
  if (tx < 0 || ty < 0 || tx >= cols || ty >= rows) return false;
  
  return map[tx][ty] == 1;
}

boolean canSpawnTank(float x, float y, float w, float h) {
  float hw = w / 2;
  float hh = h / 2;

  return
    !collidesPoint(x - hw, y - hh) &&
    !collidesPoint(x + hw, y - hh) &&
    !collidesPoint(x - hw, y + hh) &&
    !collidesPoint(x + hw, y + hh);
}

boolean isHit(Tank tank, ArrayList<Missle> missles) {
  for (int i = 0; i < missles.size(); i++) {
    Missle m = missles.get(i);
    float d = dist(tank.x, tank.y, m.x, m.y);
    
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

void drawGameVisuals() {
  pushMatrix();
  
  // Efekt wstrząsu ekranu przy trafieniu
  if (shakeAmount > 0) {
    translate(random(-shakeAmount, shakeAmount), random(-shakeAmount, shakeAmount));
    shakeAmount *= 0.9;
    if (shakeAmount < 0.5) shakeAmount = 0;
  }

  drawMap();
  
  p.display(mouseX, mouseY);
  p.displayMissles();
  
  for (Enemy e : enemies) {
    e.display(p.x, p.y);
    e.displayMissles();
  }

  // Renderowanie iskier z usuwaniem wygasłych
  for (int i = sparks.size()-1; i >= 0; i--) {
      Spark s = sparks.get(i);
      s.display();
      if (!s.alive) sparks.remove(i);
  }
  
  // Renderowanie wybuchów z usuwaniem zakończonych animacji
  for (int i = explosions.size() - 1; i >= 0; i--) {
    Explosion ex = explosions.get(i);
    ex.display();
    if (!ex.alive) explosions.remove(i);
  }

  popMatrix();
}

void drawMap() {
  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      float posX = x * tileSize;
      float posY = y * tileSize;

      if (map[x][y] == 1) {
        float hp = tileHP[x][y];
        
        shape(tileGround, posX, posY, tileSize, tileSize);

        // Progresywne uszkodzenia wizualne w zależności od HP
        if (hp > 75) {
          shape(layerFresh, posX, posY, tileSize, tileSize);
        } else if (hp > 40) {
          shape(layerLight, posX, posY, tileSize, tileSize);
        } else {
          shape(layerHeavy, posX, posY, tileSize, tileSize);
        }
      } else {
        shape(tileGround, posX, posY, tileSize, tileSize);
      }
    }
  }
}

// ============================================================
// TUTORIAL
// ============================================================

void drawTutorialGame() {
  drawGameVisuals(); // Korzystamy z Twoich gotowych funkcji rysowania mapy i gracza
  
  pushStyle();
  textAlign(CENTER);
  textSize(35);
  // Cień tekstu dla lepszej czytelności
  fill(0, 150);
  text(getTutorialText(), width/2 + 2, 102);
  // Główny tekst
  fill(255, 255, 0);
  text(getTutorialText(), width/2, 100);
  popStyle();
}

String getTutorialText() {
  switch(tutorialStep) {
    case 0: return "Użyj klawiszy WASD, aby się poruszyć";
    case 1: return "Świetnie! Teraz celuj myszką i naciśnij LPM, aby strzelić";
    case 2: return "Zniszcz dowolną przeszkodę, aby przejść dalej";
    case 3: return "Brawo! Jesteś gotowy. Naciśnij SPACJĘ, aby zacząć prawdziwą bitwę!";
    default: return "";
  }
}

void updateTutorialLogic() {
  float currentTime = millis() / 1000.0;
  float deltaTime = currentTime - lastTime;
  lastTime = currentTime;

  p.update(deltaTime);
  p.updateMissles(deltaTime);

  for (Explosion ex : explosions) {
    ex.update(deltaTime);
  }
  for (Spark s : sparks) {
    s.update(deltaTime);
  }

  // Warunki przejścia do kolejnych kroków
  if (tutorialStep == 0 && (w || a || s || d)) {
    tutorialStep = 1;
  } 
  else if (tutorialStep == 1 && p.missles.size() > 0) {
    tutorialStep = 2;
    initialWallCount = countWalls();
  } 
  else if (tutorialStep == 2 && countWalls() < initialWallCount) {
    tutorialStep = 3;
  }
}

// Funkcja pomocnicza do sprawdzania postępu
int countWalls() {
  int count = 0;
  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      if (map[x][y] == 1) count++;
    }
  }
  return count;
}


// ============================================================
// INTERFEJS UŻYTKOWNIKA
// ============================================================

// --- Menu główne --------------------------------------------

void drawMenu() {
  pushStyle();
  background(30);

  // Delikatne przyciemnienie + vignette feel
  fill(0, 0, 0, 120);
  rect(0, 0, width, height);

  textAlign(CENTER, CENTER);

  // Pulsujący tytuł
  float pulse = 1.0 + sin(frameCount * 0.08) * 0.06;
  pushMatrix();
  translate(width/2, height/2 - 180);
  scale(pulse);
  fill(255, 80, 80);
  textSize(80);
  text("TANK BATTLE", 0, 0);
  popMatrix();

  // Podtytuł
  fill(200);
  textSize(20);
  text("Zniszcz wroga. Przetrwaj jak najdłużej.", width/2, height/2 - 110);

  // Przyciski
  String[] labels = {"START", "WYJŚCIE"};
  for (int i = 0; i < labels.length; i++) {
    float bx = width/2;
    float by = height/2 + (i * 80);

    boolean hover = dist(mouseX, mouseY, bx, by) < 140 && abs(mouseY - by) < 30;

    if (hover) {
      fill(lerpColor(color(255, 80, 80), color(0), 0.25));
    } else {
      fill(90);
    }

    rectMode(CENTER);
    rect(bx, by, 320, 55, 12);

    fill(255);
    textSize(26);
    text(labels[i], bx, by - 4);
  }

  // Mały hint
  fill(150);
  textSize(14);
  text("Sterowanie: WASD + MYSZ", width/2, height - 40);

  popStyle();
}

// --- Menu pauzy ---------------------------------------------

void drawPauseMenu() {
  color pauseColor = color(0,0,255);
  pushStyle();
  fill(0, 0, 0, 180);
  rect(0, 0, width, height);
  
  textAlign(CENTER, CENTER);
  fill(0, 0, 200);
  textSize(70);
  text("PAUZA", width/2, height/2 - 150);

  String[] labels = {"WZNÓW", "ZAPISZ", "WCZYTAJ", "WYJDŹ"};
  for (int i = 0; i < labels.length; i++) {
    float bx = width/2;
    float by = height/2 - 50 + (i * 70);
    
    // Sprawdzamy czy to przycisk ZAPISZ (i=1) w trakcie tutorialu (previousState=5)
    boolean isSaveDisabled = (i == 1 && previousState == GameStatus.TUTORIAL);
    
    if (isSaveDisabled) {
      fill(50); // Ciemnoszary dla nieaktywnego przycisku
    } else if (dist(mouseX, mouseY, bx, by) < 100 && abs(mouseY - by) < 25){
      fill(lerpColor(pauseColor, color(0), 0.2));
    } else {
      fill(100);
    }
    
    rectMode(CENTER);
    rect(bx, by, 250, 50, 10);

    if (isSaveDisabled) fill(100); 
    else fill(255);

    textSize(24);
    text(labels[i], bx, by - 5);
  }
  popStyle();
}

// --- Ekrany końcowe -----------------------------------------

void gameOver() {
  drawEndScreen("PORAŻKA", color(255, 0, 0)); 
}

void Win() {
  drawEndScreen("ZWYCIĘSTWO", color(0, 255, 0)); 
}

void drawEndScreen(String title, color titleColor) {
  pushStyle();
  // Przyciemnienie tła
  fill(0, 0, 0, 180); 
  rect(0, 0, width, height);
  
  textAlign(CENTER, CENTER); 

  // Dynamiczne pulsowanie tekstu tytułowego
  float pulse = 1.0 + sin(frameCount * 0.1) * 0.05;
  pushMatrix();
  translate(width/2, height/2 - 150);
  scale(pulse);
  fill(titleColor);
  textSize(70); 
  text(title, 0, 0);
  popMatrix();

  // Przyciski stylizowane na menu pauzy
  String[] labels = {"ZAGRAJ PONOWNIE", "WYJDŹ"}; 
  for (int i = 0; i < labels.length; i++) {
    float bx = width/2;
    float by = height/2 - 20 + (i * 80); 
    
    // Logika najechania myszką (hover)
    if (dist(mouseX, mouseY, bx, by) < 125 && abs(mouseY - by) < 25) { 
      fill(lerpColor(titleColor, color(0), 0.2));
    } else {
      fill(100); 
    }
    
    rectMode(CENTER);
    rect(bx, by, 300, 50, 10); 
    
    fill(255);
    textSize(24); 
    text(labels[i], bx, by - 5);
  }
  popStyle();
}

// --- System powiadomień -------------------------------------

void drawNotification() {
  int elapsed = millis() - notificationTime;
  
  if (elapsed < displayDuration) {
    pushStyle();
    float alpha = map(elapsed, 0, displayDuration, 255, 0);
    textAlign(CENTER);
    textSize(30);
    fill(255, 255, 0, alpha);
    text(notificationText, width/2, 60); 
    popStyle();
  }
}

void showNotify(String msg) {
  notificationText = msg;
  notificationTime = millis();
}


// ============================================================
// OBSŁUGA INPUTU
// ============================================================

void mousePressed() {

  if (gameState == GameStatus.MENU) {
    // Sprawdzamy czy myszka jest w poziomie (X) w zakresie przycisków
    if (mouseX > width/2 - 160 && mouseX < width/2 + 160) {
      
      // Przycisk START (by = height/2)
      if (mouseY > height/2 - 27 && mouseY < height/2 + 27) {
        gameState = GameStatus.TUTORIAL; // Zamiast 1, idziemy do tutorialu
        tutorialStep = 0;
        generateMap(); // Generujemy czystą mapę do ćwiczeń
        lastTime = millis() / 1000.0;
      }
      
      // Przycisk WYJŚCIE (by = height/2 + 80)
      if (mouseY > height/2 + 80 - 27 && mouseY < height/2 + 80 + 27) {
        exit();
      }
    }
    
  }else if (gameState == GameStatus.GAMEOVER || gameState == GameStatus.WIN) { // Ekrany końcowe
    if (mouseX > width/2 - 150 && mouseX < width/2 + 150) {
      // Przycisk "Zagraj ponownie"
      if (mouseY > height/2 - 45 && mouseY < height/2 + 5) {
        resetGame();
        gameState = GameStatus.PLAY;
        lastTime = millis() / 1000.0; 
      }
      // Przycisk "Wyjdź"
      if (mouseY > height/2 + 35 && mouseY < height/2 + 85) {
        exit();
      }
    }
  } else if (gameState == GameStatus.PAUSE) {
    if (mouseX > width/2 - 125 && mouseX < width/2 + 125) {
      if (mouseY > height/2 - 75 && mouseY < height/2 - 25) gameState = previousState;
      if (mouseY > height/2 - 5 && mouseY < height/2 + 45) {
        if (previousState != GameStatus.TUTORIAL) {
          saveGameWithDialog();
        } else {
          showNotify("NIE MOŻNA ZAPISAĆ W TUTORIALU");
        }
      }
      if (mouseY > height/2 + 65 && mouseY < height/2 + 115) loadGameWithDialog();
      if (mouseY > height/2 + 135 && mouseY < height/2 + 185) exit();
    }
  } else if (gameState == GameStatus.PLAY || gameState == GameStatus.TUTORIAL) {
    p.shoot(mouseX, mouseY); 
    file.play(); 
  }
}

void keyPressed(){
  // Obsługa ESC bez zamykania programu
  if (key == ESC) {
    key = 0;
    if (gameState == GameStatus.PLAY || gameState == GameStatus.TUTORIAL) {
      previousState = gameState;
      gameState = GameStatus.PAUSE;
    } else if (gameState == GameStatus.PAUSE) {
      gameState = previousState;
      lastTime = millis() / 1000.0;
    }
  }
  
  if (key == 'w' || key == 'W') w = true;
  if (key == 'a' || key == 'A') a = true;
  if (key == 's' || key == 'S') s = true;
  if (key == 'd' || key == 'D') d = true;
  
  if (key == 'q' || key == 'Q') {
    exit(); 
  }

  if (key == 'r' || key == 'R') {
    resetGame();
    gameState = GameStatus.PLAY; 
    lastTime = millis() / 1000.0;
  }

  if (key == 'k' || key == 'K') {
    saveGameWithDialog();
  }
  
  if (key == 'l' || key == 'L') {
    loadGameWithDialog();
  }

  if (gameState == GameStatus.TUTORIAL && tutorialStep == 3 && key == ' ') {
    gameState = GameStatus.PLAY; 
    calculateTilesize(desiredCols);
    resetGame(); 
    lastTime = millis() / 1000.0;
  }
}

void keyReleased(){
  if (key == 'w' || key == 'W') w = false;
  if (key == 'a' || key == 'A') a = false;
  if (key == 's' || key == 'S') s = false;
  if (key == 'd' || key == 'D') d = false;
}


// ============================================================
// ZAPIS I WCZYTYWANIE GRY
// ============================================================

void saveGameWithDialog() {
  if (enemies.isEmpty()){
    showNotify("BRAK WROGÓW");
  }
    
  JFileChooser fileChooser = new JFileChooser();
  fileChooser.setDialogTitle("Zapisz grę");
  
  File dataFolder = new File(sketchPath("data"));
  if (!dataFolder.exists()) {
    dataFolder.mkdir();
  }
  
  fileChooser.setCurrentDirectory(dataFolder);
  
  // Automatyczne generowanie nazwy pliku
  String baseName = "gameSave";
  String extension = ".json";
  String suggestedName = baseName + extension;
  int counter = 1;
  
  while (new File(dataFolder, suggestedName).exists()) {
    suggestedName = baseName + "_" + counter + extension;
    counter++;
  }
  
  fileChooser.setSelectedFile(new File(suggestedName));
  
  FileNameExtensionFilter filter = new FileNameExtensionFilter("Pliki JSON (*.json)", "json");
  fileChooser.setFileFilter(filter);
  fileChooser.setAcceptAllFileFilterUsed(false);
  
  int userSelection = fileChooser.showSaveDialog(null);
  
  if (userSelection == JFileChooser.APPROVE_OPTION) {
    File fileToSave = fileChooser.getSelectedFile();
    String path = fileToSave.getAbsolutePath();
    
    if (!path.toLowerCase().endsWith(".json")) {
      path += ".json";
    }
    
    saveGameToFile(path, fileToSave.getName());
  } else {
    showNotify("ANULOWANO ZAPIS");
  }
}

void saveGameToFile(String path, String fileName) {
  
  JSONObject saveFile = new JSONObject();

  // Serializacja danych gracza
  JSONObject playerData = new JSONObject();
  playerData.setFloat("x", p.x);
  playerData.setFloat("y", p.y);
  playerData.setFloat("hp", p.hp);
  saveFile.setJSONObject("player", playerData);

  // Serializacja wrogów
  JSONArray enemiesData = new JSONArray();
  for (int i = 0; i < enemies.size(); i++) {
    Enemy e = enemies.get(i);
    JSONObject singleEnemy = new JSONObject();
    singleEnemy.setFloat("x", e.x);
    singleEnemy.setFloat("y", e.y);
    singleEnemy.setFloat("hp", e.hp);
    enemiesData.setJSONObject(i, singleEnemy);
  }
  saveFile.setJSONArray("enemies", enemiesData);

  // Serializacja struktury mapy
  JSONArray mapData = new JSONArray();
  for (int y = 0; y < rows; y++) {
    String rowString = "";
    for (int x = 0; x < cols; x++) {
      rowString += map[x][y];
    }
    mapData.append(rowString);
  }
  saveFile.setJSONArray("map", mapData);

  // Zapis tylko uszkodzonych ścian (optymalizacja rozmiaru pliku)
  JSONObject damagedWalls = new JSONObject();
  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      if (map[x][y] == 1 && tileHP[x][y] < 100) {
        String key = x + "," + y;
        damagedWalls.setFloat(key, tileHP[x][y]);
      }
    }
  }
  saveFile.setJSONObject("damagedWalls", damagedWalls);

  saveJSONObject(saveFile, path);
  showNotify("GRA ZAPISANA: " + fileName);
  println("Gra zapisana w: " + path);
}

void loadGameWithDialog() {
  gameState = GameStatus.PLAY;
  JFileChooser fileChooser = new JFileChooser();
  fileChooser.setDialogTitle("Wczytaj grę");
  
  File dataFolder = new File(sketchPath("data"));
  if (!dataFolder.exists()) {
    dataFolder.mkdir();
  }
  
  fileChooser.setCurrentDirectory(dataFolder);
  
  FileNameExtensionFilter filter = new FileNameExtensionFilter("Pliki JSON (*.json)", "json");
  fileChooser.setFileFilter(filter);
  fileChooser.setAcceptAllFileFilterUsed(false);
  
  int userSelection = fileChooser.showOpenDialog(null);
  
  if (userSelection == JFileChooser.APPROVE_OPTION) {
    File fileToLoad = fileChooser.getSelectedFile();
    String path = fileToLoad.getAbsolutePath();
    loadGameFromFile(path, fileToLoad.getName());
  } else {
    showNotify("ANULOWANO WCZYTYWANIE");
  }
}

void loadGameFromFile(String path, String fileName) {
  
  try {
    JSONObject saveFile = loadJSONObject(path);

    // Deserializacja mapy
    JSONArray mapData = saveFile.getJSONArray("map");
    rows = mapData.size();
    
    if (rows > 0) {
      String firstRow = mapData.getString(0);
      cols = firstRow.length();
    }
    
    tileSize = width / (float)cols;
    desiredCols = cols;
    map = new int[cols][rows];
    tileHP = new float[cols][rows];

    for (int y = 0; y < rows; y++) {
      String rowString = mapData.getString(y);
      for (int x = 0; x < cols; x++) {
        char c = rowString.charAt(x);
        if (c == '1') {
          map[x][y] = 1;
          tileHP[x][y] = 100;
        } else {
          map[x][y] = 0;
          tileHP[x][y] = 0;
        }
      }
    }

    // Wczytanie stanu uszkodzeń
    if (saveFile.hasKey("damagedWalls")) {
      JSONObject damagedWalls = saveFile.getJSONObject("damagedWalls");
      
      for (Object keyObj : damagedWalls.keys()) {
        String key = (String) keyObj;
        float hp = damagedWalls.getFloat(key);
        
        String[] coords = key.split(",");
        int x = Integer.parseInt(coords[0]);
        int y = Integer.parseInt(coords[1]);
        
        tileHP[x][y] = hp;
      }
    }

    // Deserializacja gracza
    p = new Player(tankPlayerBottomImg, tankPlayerGunImg, misslePlayerImg);
    JSONObject playerData = saveFile.getJSONObject("player");
    p.x = playerData.getFloat("x");
    p.y = playerData.getFloat("y");
    p.hp = playerData.getFloat("hp");

    // Deserializacja wrogów
    JSONArray enemiesData = saveFile.getJSONArray("enemies");
    enemies.clear();
    for (int i = 0; i < enemiesData.size(); i++) {
      JSONObject singleEnemy = enemiesData.getJSONObject(i);
      Enemy newEnemy = new Enemy(tankEnemyBottomImg, tankEnemyGunImg, missleEnemyImg);
      newEnemy.x = singleEnemy.getFloat("x");
      newEnemy.y = singleEnemy.getFloat("y");
      newEnemy.hp = singleEnemy.getFloat("hp");
      enemies.add(newEnemy);
    }

    numberOfEnemies = enemies.size();
    gameState = GameStatus.PLAY;
    loop();
    showNotify("WCZYTANO: " + fileName);
    println("Wczytano grę z: " + path);
    
  } catch (Exception e) {
    showNotify("BŁĄD WCZYTYWANIA!");
    println("Błąd przy wczytywaniu: " + e.getMessage());
  }
}

class Missle {
  float x, y;
  float angle;
  float speed = tileSize*6;
  PShape imgMissile;
  float w, h;

  Missle(float x, float y, float angle, PShape imgMissile){
    this.x = x;
    this.y = y;
    this.angle = angle;
    this.imgMissile = imgMissile;
    w = tileSize * 0.6;
    h = w * 1.4;
  }

  void update(float deltaTime) {
    float nextX = x + cos(angle) * speed * deltaTime; 
    float nextY = y + sin(angle) * speed * deltaTime; 

    // Sprawdzenie kolizji przed przesunięciem
    if (collidesPoint(nextX, nextY)) {
      applyTileDamage(nextX, nextY);
      w = 0; h = 0;
      return;
    }

    x = nextX; 
    y = nextY;

    // Implementacja teleportacji przez krawędzie ekranu
    boolean teleported = false;
    if (x < 0) { x = width; teleported = true; }
    else if (x > width) { x = 0; teleported = true; }
    
    if (y < 0) { y = height; teleported = true; }
    else if (y > height) { y = 0; teleported = true; }

    // Sprawdzenie kolizji po teleportacji
    if (teleported && collidesPoint(x, y)) {
      applyTileDamage(x, y);
      w = 0; h = 0;
    }
  }

  void applyTileDamage(float checkX, float checkY) {
    int tx = int(checkX / tileSize); 
    int ty = int(checkY / tileSize);
    
    if (tx >= 0 && tx < cols && ty >= 0 && ty < rows) { 
      if (map[tx][ty] == 1) {
        tileHP[tx][ty] -= 3;
        explosions.add(new Explosion(checkX, checkY, explosionImg));
        if (tileHP[tx][ty] <= 0) {
          map[tx][ty] = 0;
        }
      }
    }
  }

  void display(){
    pushMatrix();
    translate(x, y);
    rotate(angle + HALF_PI); 
    shape(imgMissile, -w/2, -h/2, w, h);
    popMatrix();
  }

  boolean isOffScreen(){
    return x < 0 || x > width || y < 0 || y > height;
  }
}

class Explosion {
  float x, y, rotation;
  float timer = 0;
  float sizeMod;
  PShape sFlash, sFire, sSmoke;
  boolean alive = true;

  Explosion(float x, float y, PShape svg) {
    this.x = x;
    this.y = y;
    this.rotation = random(TWO_PI);
    this.sizeMod = random(1.0, 1.4);
    
    sFlash = svg.getChild("flash");
    sFire = svg.getChild("fire");
    sSmoke = svg.getChild("smoke");
  }

  void update(float dt) {
    timer += dt;
    if (timer > 0.7) alive = false;
  }

  void display() {
    if (!alive) return;
    
    pushMatrix();
    translate(x, y);
    rotate(rotation);
    
    float baseSize = tileSize * 0.7; 
    
    // Dynamiczna skala początkowego uderzenia
    float impactScale = (timer < 0.1) ? map(timer, 0, 0.1, 0.3, 1.1) : 1.0;
    scale(impactScale * sizeMod);
    
    // Sekwencja animacji warstw wybuchu
    sFlash.setVisible(timer < 0.15);
    sFire.setVisible(timer >= 0.1 && timer < 0.45);
    sSmoke.setVisible(timer >= 0.35);
    
    float offset = -baseSize / 2;
    
    shape(sSmoke, offset, offset, baseSize, baseSize);
    shape(sFire, offset, offset, baseSize, baseSize);
    shape(sFlash, offset, offset, baseSize, baseSize);
    
    popMatrix();
  }
}

class Spark {
  float x, y, vx, vy;
  float timer = 0;
  boolean alive = true;
  PShape sDark, sLight, sSparks;
  float size;

  Spark(float x, float y, PShape svg) {
    this.x = x;
    this.y = y;
    
    this.size = tileSize * 0.30; 
    
    this.vx = random(-tileSize * 2, tileSize * 2); 
    this.vy = random(-tileSize * 2, tileSize * 2);
    
    sDark = svg.getChild("dark");
    sLight = svg.getChild("light");
    sSparks = svg.getChild("sparks");
  }

  void update(float dt) {
    x += vx * dt;
    y += vy * dt;
    timer += dt;
    if (timer > 0.35) alive = false; 
  }

  void display() {
    pushMatrix();
    translate(x, y);
    rotate(timer * 12); 

    sDark.setVisible(true);
    sLight.setVisible(frameCount % 2 == 0); 
    sSparks.setVisible(frameCount % 3 != 0); 
    
    float offset = -size / 2;
    shape(sDark, offset, offset, size, size);
    shape(sLight, offset, offset, size, size);
    shape(sSparks, offset, offset, size, size);
    
    popMatrix();
  }
}

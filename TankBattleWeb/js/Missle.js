class Missle {
       constructor(x, y, angle, type) { // type: 'player' lub 'enemy'
        this.x = x;
        this.y = y;
        this.angle = angle;
        this.type = type;
        this.speed = tileSize * 6;
        this.w = tileSize * 0.4;
        this.h = this.w * 1.4;
    }
    
    display() {
        if (this.type === 'player') {
            drawMissilePlayer(this.x, this.y, this.w, this.h, this.angle + HALF_PI);
        } else {
            drawMissileEnemy(this.x, this.y, this.w, this.h, this.angle + HALF_PI);
        }
    }
    
    update(deltaTime) {
        let nextX = this.x + cos(this.angle) * this.speed * deltaTime;
        let nextY = this.y + sin(this.angle) * this.speed * deltaTime;
        
        if (collidesPoint(nextX, nextY)) {
            this.applyTileDamage(nextX, nextY);
            this.w = 0;
            this.h = 0;
            return;
        }
        
        this.x = nextX;
        this.y = nextY;
        
        let teleported = false;
        if (this.x < 0) {
            this.x = width;
            teleported = true;
        } else if (this.x > width) {
            this.x = 0;
            teleported = true;
        }
        
        if (this.y < 0) {
            this.y = height;
            teleported = true;
        } else if (this.y > height) {
            this.y = 0;
            teleported = true;
        }
        
        if (teleported && collidesPoint(this.x, this.y)) {
            this.applyTileDamage(this.x, this.y);
            this.w = 0;
            this.h = 0;
        }
    }
    
    applyTileDamage(checkX, checkY) {
        let tx = int(checkX / tileSize);
        let ty = int(checkY / tileSize);
        
        if (tx >= 0 && tx < cols && ty >= 0 && ty < rows) {
            if (gameMap[tx][ty] === 1) {
                tileHP[tx][ty] -= 3;
                explosions.push(new Explosion(checkX, checkY));
                if (tileHP[tx][ty] <= 0) {
                    gameMap[tx][ty] = 0;
                }
            }
        }
    }
    
    
    isOffScreen() {
        return this.x < 0 || this.x > width || this.y < 0 || this.y > height;
    }
}
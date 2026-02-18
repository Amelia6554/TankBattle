class Tank {
       constructor(x, y, speed, hp, type) { // type: 'player' lub 'enemy'
        this.x = x;
        this.y = y;
        this.widthTank = tileSize * 0.7;
        this.heightTank = tileSize * 0.7;
        this.vx = 0;
        this.vy = 0;
        this.angle = 0;
        this.hp = hp;
        this.maxHp = hp;
        this.maxSpeed = speed;
        this.speed = speed;
        this.type = type; // 'player' lub 'enemy'
        this.missles = [];
    }
    
    display(targetX, targetY) {
        let isDamaged = (this.hp < this.maxHp * 0.5);
        
        // Renderowanie kadłuba
        if (this.type === 'player') {
            drawTankPlayerBottom(this.x, this.y, this.widthTank, this.heightTank, this.angle + HALF_PI);
        } else {
            drawTankEnemyBottom(this.x, this.y, this.widthTank, this.heightTank, this.angle + HALF_PI);
        }
        
        // Renderowanie wieżyczki
        let gunAngle = Math.atan2(targetY - this.y, targetX - this.x);
        if (this.type === 'player') {
            drawTankPlayerGun(this.x, this.y, this.widthTank, this.heightTank, gunAngle);
        } else {
            drawTankEnemyGun(this.x, this.y, this.widthTank, this.heightTank, gunAngle);
        }
        
        // Pasek HP (bez zmian)
        if (this.hp < this.maxHp && this.hp > 0) {
            push();
            noStroke();
            rectMode(CENTER);
            fill(255, 0, 0);
            rect(this.x, this.y - this.heightTank/1.5, 40, 6);
            let hpPercent = this.hp / this.maxHp;
            let greenWidth = 40 * hpPercent;
            rectMode(CORNER);
            fill(0, 255, 0);
            rect(this.x - 20, this.y - this.heightTank/1.5 - 3, greenWidth, 6);
            pop();
        }
    }
    
    shoot(targetX, targetY) {
        let gunAngle = Math.atan2(targetY - this.y, targetX - this.x);
        let gunLength = this.widthTank/2 + this.widthTank/3;
        let sx = this.x + Math.cos(gunAngle) * gunLength;
        let sy = this.y + Math.sin(gunAngle) * gunLength;
        this.missles.push(new Missle(sx, sy, gunAngle, this.type)); // Przekazujemy typ
    }
    
    move(dx, dy, deltaTime) {
        if (dx !== 0 || dy !== 0) {
            let len = Math.sqrt(dx*dx + dy*dy);
            dx /= len;
            dy /= len;
            this.angle = Math.atan2(dy, dx);
        }
        
        this.vx = dx * this.speed;
        this.vy = dy * this.speed;
        
        let nextX = this.x + this.vx * deltaTime;
        let nextY = this.y + this.vy * deltaTime;
        let hitboxScale = 0.5;
        
        let tankCollisionX = this.collidesWithTanks(nextX, this.y);
        let mapCollisionX = collidesPlayer(nextX, this.y, this.widthTank * hitboxScale, this.heightTank * hitboxScale);
        
        if (!tankCollisionX && !mapCollisionX) {
            this.x = nextX;
        } else if (mapCollisionX && frameCount % 4 === 0) {
            sparks.push(new Spark(nextX, this.y));
        }
        
        let tankCollisionY = this.collidesWithTanks(this.x, nextY);
        let mapCollisionY = collidesPlayer(this.x, nextY, this.widthTank * hitboxScale, this.heightTank * hitboxScale);
        
        if (!tankCollisionY && !mapCollisionY) {
            this.y = nextY;
        } else if (mapCollisionY && frameCount % 4 === 0) {
            sparks.push(new Spark(this.x, nextY));
        }
        
        // Teleportacja przez krawędzie z weryfikacją
        if (this.x < -this.widthTank/2) {
            let targetTx = cols - 1;
            let targetTy = Math.floor(this.y / tileSize);
            if (targetTy >= 0 && targetTy < rows && gameMap[targetTx][targetTy] === 0) {
                this.x = width + this.widthTank/2;
            } else {
                this.x = -this.widthTank/2;
            }
        } else if (this.x > width + this.widthTank/2) {
            let targetTx = 0;
            let targetTy = Math.floor(this.y / tileSize);
            if (targetTy >= 0 && targetTy < rows && gameMap[targetTx][targetTy] === 0) {
                this.x = -this.widthTank/2;
            } else {
                this.x = width + this.widthTank/2;
            }
        }
        
        if (this.y < -this.heightTank/2) {
            let targetTx = Math.floor(this.x / tileSize);
            let targetTy = rows - 1;
            if (targetTx >= 0 && targetTx < cols && gameMap[targetTx][targetTy] === 0) {
                this.y = height + this.heightTank/2;
            } else {
                this.y = -this.heightTank/2;
            }
        } else if (this.y > height + this.heightTank/2) {
            let targetTx = Math.floor(this.x / tileSize);
            let targetTy = 0;
            if (targetTx >= 0 && targetTx < cols && gameMap[targetTx][targetTy] === 0) {
                this.y = -this.heightTank/2;
            } else {
                this.y = height + this.heightTank/2;
            }
        }
    }
    
    updateMissles(dt) {
        for (let i = this.missles.length - 1; i >= 0; i--) {
            let m = this.missles[i];
            m.update(dt);
            if (m.isOffScreen() || m.h <= 0) {
                this.missles.splice(i, 1);
            }
        }
    }
    
    displayMissles() {
        for (let m of this.missles) {
            m.display();
        }
    }
    
    collidesWithTanks(nextX, nextY) {
        let minDistance = this.widthTank * 0.8;
        
        // Sprawdzenie kolizji z graczem (jeśli nie jesteśmy graczem)
        if (this !== p && dist(nextX, nextY, p.x, p.y) < minDistance) {
            return true;
        }
        
        // Sprawdzenie kolizji z innymi wrogami
        for (let other of enemies) {
            if (this !== other && dist(nextX, nextY, other.x, other.y) < minDistance) {
                return true;
            }
        }
        
        return false;
    }
    
    subtractHP(amount) {
        this.hp -= amount;
        return this.hp > 0;
    }
    
    // Abstrakcyjna metoda - musi być zaimplementowana w klasach pochodnych
    update(dt) {
        throw new Error("Metoda 'update' musi być zaimplementowana w klasie pochodnej");
    }
}
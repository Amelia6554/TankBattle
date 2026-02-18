class Explosion {
    constructor(x, y) {
        this.x = x;
        this.y = y;
        this.rotation = random(TWO_PI);
        this.sizeMod = random(1.0, 1.4);
        this.timer = 0;
        this.alive = true;
    }
    
    update(dt) {
        this.timer += dt;
        if (this.timer > 0.7) this.alive = false;
    }
    
    display() {
        if (!this.alive) return;
        
        push();
        translate(this.x, this.y);
        rotate(this.rotation);
        
        let baseSize = 28;
        let impactScale = (this.timer < 0.1) ? map(this.timer, 0, 0.1, 0.3, 1.1) : 1.0;
        let size = baseSize * impactScale * this.sizeMod;
        
        let alpha = map(this.timer, 0, 0.7, 255, 0);
        
        // Rysuj eksplozję jako kilka okręgów
        noStroke();
        fill(255, 150, 0, alpha); // Pomarańczowy
        ellipse(0, 0, size, size);
        fill(255, 255, 0, alpha * 0.7); // Żółty w środku
        ellipse(0, 0, size * 0.6, size * 0.6);
        fill(255, 0, 0, alpha * 0.5); // Czerwony akcent
        ellipse(0, 0, size * 0.3, size * 0.3);
        
        pop();
    }
}

class Spark {
    constructor(x, y) {
        this.x = x;
        this.y = y;
        this.vx = random(-80, 80);
        this.vy = random(-80, 80);
        this.timer = 0;
        this.alive = true;
        this.size = 12;
    }
    
    update(dt) {
        this.x += this.vx * dt;
        this.y += this.vy * dt;
        this.timer += dt;
        if (this.timer > 0.35) this.alive = false;
    }
    
    display() {
        push();
        translate(this.x, this.y);
        rotate(this.timer * 12);
        
        let alpha = map(this.timer, 0, 0.35, 255, 0);
        
        // Rysuj iskrę jako gwiazdkę
        noStroke();
        fill(255, 255, 0, alpha);
        for (let i = 0; i < 4; i++) {
            rotate(HALF_PI);
            triangle(0, -this.size/2, -this.size/4, 0, 0, this.size/2);
        }
        
        pop();
    }
}
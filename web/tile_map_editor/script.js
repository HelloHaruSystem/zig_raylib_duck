// constants
const classes = ['grass', 'wall', 'water'];
// HTML elements
const grid = document.getElementById('grid');
const create = document.getElementById('create-grid');
const clear = document.getElementById('clear-grid');
const border = document.getElementById('add-border');
const spawn = document.getElementById('toggle-spawn-mode');
const download = document.getElementById("download-map");
const copy = document.getElementById("copy-to-clipboard");
const upload = document.getElementById("upload-file-to-edit");
const grassTile = document.getElementById('grass-tile');
const wallTile = document.getElementById('wall-tile');
const waterTile = document.getElementById('water-tile');
const widthInput = document.getElementById('width');
const heightInput = document.getElementById('height');
const mapNameInput = document.getElementById('mapName');

// global variables
let gridWidth = 16;
let gridHeight = 9;
let selectedTile = 0;
let spawnX = 1;
let spawnY = 1;
let spawnMode = false;
let tiles = [];
let isMouseDown = false;

const createGrid = () => {
    gridWidth = parseInt(document.getElementById('width').value);
    gridHeight = parseInt(document.getElementById('height').value);
    
    if (gridWidth < 5 || gridWidth > 50 || gridHeight < 5 || gridHeight > 50) {
        alert('Grid size must be between 5x5 and 50x50');
        return;
    }

    // inti tile arr
    tiles = [];
    for (let y = 0; y < gridHeight; y++) {
        tiles[y] = [];
        for (let x = 0; x < gridWidth; x++) {
            tiles[y][x] = 0; // zero = grass
        }
    }

    // create the visual grid
    grid.style.gridTemplateColumns = `repeat(${gridWidth}, 1fr)`;
    grid.innerHTML = '';

    for (let y = 0; y < gridHeight; y++) {
        for (let x = 0; x < gridWidth; x++) {
            const tile = document.createElement('div');
            tile.className= 'tile grass';
            tile.dataset.x = x;
            tile.dataset.y = y;

            tile.addEventListener('mousedown', () => {
                isMouseDown = true;
                handleTileClick(x, y);
            });
            
            tile.addEventListener('mouseenter', () => {
                if (isMouseDown) {
                    handleTileClick(x, y);
                }
            });
            
            grid.appendChild(tile);
        }
    }

    // make sure spawn is within bounds
    if (spawnX >= gridWidth) spawnX = gridWidth - 1;
    if (spawnY >= gridHeight) spawnY = gridHeight -1;

    updateSpawnDisplay();
    generateOutput();
};

const handleTileClick = (x, y) => {
    if (spawnMode) {
        spawnX = x;
        spawnY = y;
        updateSpawnDisplay(); 
    } else {
        tiles[y][x] = selectedTile;
        updateTileVisual(x, y);
    }
    generateOutput();
}

const updateTileVisual = (x, y) => {
    const tileElement = document.querySelector(`[data-x="${x}"][data-y="${y}"]`);
    const tileType = tiles[y][x];
    
    tileElement.className = `tile ${classes[tileType]}`;

    // add spawn indicator if this is the spawn tile
    if (x === spawnX && y === spawnY) {
        tileElement.classList.add('spawn');
    }
}

const updateSpawnDisplay = () => {
    // remove spawn class form all tiles
    document.querySelectorAll('.tile').forEach(tile => {
        tile.classList.remove('spawn');
    });

    // add spawn to spawn tile
    const spawnTile = document.querySelector(`[data-x="${spawnX}"][data-y="${spawnY}"]`);
    if (spawnTile) {
        spawnTile.classList.add('spawn');
    }
    
    document.getElementById('spawnInfo').textContent = `X=${spawnX}, Y=${spawnY}`;
};

const selectTile = (tileType) => {
    selectedTile = tileType;
    spawnMode = false;

    // update button selection
    document.querySelectorAll('.tile-buttons button').forEach(button => {
        button.classList.remove('selected');
    });

    // Fixed: use correct button IDs
    const buttonIds = ['grass-tile', 'wall-tile', 'water-tile'];
    document.getElementById(buttonIds[tileType]).classList.add('selected');
    
    document.getElementById('mode').textContent = 'Mode: Paint Tiles';
};

const toggleSpawnMode = () => {
    spawnMode = !spawnMode;
    
    document.querySelectorAll('.tile-buttons button').forEach(btn => {
        btn.classList.remove('selected');
    });
    
    if (spawnMode) {
        document.getElementById('mode').textContent = 'Mode: Set Spawn Point';
    } else {
        document.getElementById('mode').textContent = 'Mode: Paint Tiles';
        const buttonIds = ['grass-tile', 'wall-tile', 'water-tile'];
        document.getElementById(buttonIds[selectedTile]).classList.add('selected');
    }
}

const clearGrid = () => {
    if (confirm('Clear the entire grid?')) {
        for (let y = 0; y < gridHeight; y++) {
            for (let x = 0; x < gridWidth; x++) {
                tiles[y][x] = 0;
                updateTileVisual(x, y);
            }
        }
        generateOutput();
    }
}

const addBorder = () => {
    // Fill top and bottom rows
    for (let x = 0; x < gridWidth; x++) {
        tiles[0][x] = 1;
        tiles[gridHeight - 1][x] = 1;
        updateTileVisual(x, 0);
        updateTileVisual(x, gridHeight - 1);
    }
    
    // Fill left and right columns
    for (let y = 0; y < gridHeight; y++) {
        tiles[y][0] = 1;
        tiles[y][gridWidth - 1] = 1;
        updateTileVisual(0, y);
        updateTileVisual(gridWidth - 1, y);
    }
    
    generateOutput();
}

const generateOutput= () => {
    const mapName = document.getElementById('mapName').value || 'unnamed_map';
    let output = `# ${mapName}\n`;
    output += `# 0 = grass, 1 = wall, 2 = water\n`;
    output += `WIDTH=${gridWidth}\n`;
    output += `HEIGHT=${gridHeight}\n`;
    output += `SPAWN_X=${spawnX}\n`;
    output += `SPAWN_Y=${spawnY}\n`;
    output += `DATA=\n`;

    for (let y = 0; y < gridHeight; y++) {
        output += tiles[y].join('') + '\n';
    }

    document.getElementById('output').value = output;
}

const downloadMap = () => {
    const content = document.getElementById('output').value;
    const mapName = document.getElementById('mapName').value || 'unnamed_map';
    
    const blob = new Blob([content], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    
    const a = document.createElement('a');
    a.href = url;
    a.download = `${mapName}.map`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
}

const copyToClipboard = () => {
    const output = document.getElementById('output');
    output.select();
    document.execCommand('copy');
    alert('Map data copied to clipboard!');
}

const uploadMapFile = () => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '.map,.txt';
    
    input.onchange = (event) => {
        const file = event.target.files[0];
        if (!file) return;
        
        const reader = new FileReader();
        reader.onload = (e) => {
            try {
                parseMapFile(e.target.result);
                alert(`Map "${file.name}" loaded successfully!`);
            } catch (error) {
                alert(`Error loading map file: ${error.message}`);
            }
        };
        reader.readAsText(file);
    };
    
    input.click();
}

const parseMapFile = (content) => {
    const lines = content.split('\n');
    let width = 0;
    let height = 0;
    let spawnXParsed = 1;
    let spawnYParsed = 1;
    let mapName = 'uploaded_map';
    let parsingData = false;
    let tileData = [];
    
    for (let line of lines) {
        line = line.trim();
        
        // Skip empty lines and comments
        if (!line || line.startsWith('#')) {
            // Try to extract map name from first comment
            if (line.startsWith('#') && !mapName && line.length > 2) {
                const nameMatch = line.match(/# (.+)/);
                if (nameMatch && !nameMatch[1].includes('=')) {
                    mapName = nameMatch[1];
                }
            }
            continue;
        }
        
        if (line.startsWith('WIDTH=')) {
            width = parseInt(line.split('=')[1]);
        } else if (line.startsWith('HEIGHT=')) {
            height = parseInt(line.split('=')[1]);
        } else if (line.startsWith('SPAWN_X=')) {
            spawnXParsed = parseInt(line.split('=')[1]);
        } else if (line.startsWith('SPAWN_Y=')) {
            spawnYParsed = parseInt(line.split('=')[1]);
        } else if (line === 'DATA=') {
            parsingData = true;
        } else if (parsingData) {
            // Parse tile data row
            if (line.length === width) {
                const row = [];
                for (let char of line) {
                    const tileId = parseInt(char);
                    if (tileId >= 0 && tileId <= 2) {
                        row.push(tileId);
                    } else {
                        throw new Error(`Invalid tile ID: ${char}`);
                    }
                }
                tileData.push(row);
            }
        }
    }
    
    // Validate data
    if (width < 5 || width > 50 || height < 5 || height > 50) {
        throw new Error('Map dimensions must be between 5x5 and 50x50');
    }
    
    if (tileData.length !== height) {
        throw new Error(`Expected ${height} rows, got ${tileData.length}`);
    }
    
    // Update the editor with loaded data
    gridWidth = width;
    gridHeight = height;
    spawnX = Math.max(0, Math.min(spawnXParsed, width - 1));
    spawnY = Math.max(0, Math.min(spawnYParsed, height - 1));
    tiles = tileData;
    
    // Update UI
    document.getElementById('width').value = width;
    document.getElementById('height').value = height;
    document.getElementById('mapName').value = mapName;
    
    // Recreate the visual grid
    grid.style.gridTemplateColumns = `repeat(${gridWidth}, 1fr)`;
    grid.innerHTML = '';
    
    for (let y = 0; y < gridHeight; y++) {
        for (let x = 0; x < gridWidth; x++) {
            const tile = document.createElement('div');
            tile.className = `tile ${classes[tiles[y][x]]}`;
            tile.dataset.x = x;
            tile.dataset.y = y;

            tile.addEventListener('mousedown', () => {
                isMouseDown = true;
                handleTileClick(x, y);
            });
            
            tile.addEventListener('mouseenter', () => {
                if (isMouseDown) {
                    handleTileClick(x, y);
                }
            });
            
            grid.appendChild(tile);
        }
    }
    
    updateSpawnDisplay();
    generateOutput();
}

// event handlers
create.addEventListener('click', () => {
    createGrid();
});

clear.addEventListener('click', () => {
    clearGrid();
});

border.addEventListener('click', () => {
    addBorder();
});

spawn.addEventListener('click', () => {
    toggleSpawnMode();
});

download.addEventListener('click', () => {
    downloadMap();
});

copy.addEventListener('click', () => {
    copyToClipboard();
});

grassTile.addEventListener('click', () => { 
    selectTile(0);
});


wallTile.addEventListener('click', () => { 
    selectTile(1);
});

waterTile.addEventListener('click', () => {
    selectTile(2);
});

widthInput.addEventListener('input', () => {
    createGrid();
});

heightInput.addEventListener('input', () => {
    createGrid();
});

mapNameInput.addEventListener('input', () => {
    generateOutput();
});

upload.addEventListener('click', () => {
    uploadMapFile();
});

// Mouse event handlers
document.addEventListener('mouseup', () => {
    isMouseDown = false;
});

// Initialize grid when page loads
document.addEventListener('DOMContentLoaded', () => {
    createGrid();
});
<?php
/**
 * Orbitica Core - HiScore API
 * URL: http://formazioneweb.org/orbitica/score.php
 * 
 * Endpoints:
 * - GET  ?action=list         -> Restituisce top 10 punteggi
 * - POST ?action=save         -> Salva nuovo punteggio
 *        body: {initials, score, wave, deviceId}
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Gestione preflight OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Configurazione database
$db_config = [
    'host' => 'localhost',
    'user' => 'orbitica_user',  // MODIFICA con il tuo user
    'password' => 'PASSWORD_SICURA',  // MODIFICA con la tua password
    'database' => 'orbitica',
    'charset' => 'utf8mb4'
];

// Connessione database
try {
    $mysqli = new mysqli(
        $db_config['host'],
        $db_config['user'],
        $db_config['password'],
        $db_config['database']
    );
    
    if ($mysqli->connect_error) {
        throw new Exception('Database connection failed: ' . $mysqli->connect_error);
    }
    
    $mysqli->set_charset($db_config['charset']);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Database connection error'
    ]);
    exit;
}

// Routing
$action = $_GET['action'] ?? 'list';

switch ($action) {
    case 'list':
        getTopScores($mysqli);
        break;
    
    case 'save':
        saveScore($mysqli);
        break;
    
    default:
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'Invalid action'
        ]);
}

$mysqli->close();

// ============================================
// FUNZIONI
// ============================================

/**
 * Restituisce top 10 punteggi
 */
function getTopScores($mysqli) {
    $stmt = $mysqli->prepare("
        SELECT 
            player_initials as initials,
            score,
            wave,
            DATE_FORMAT(date_created, '%Y-%m-%d') as date
        FROM hiscores
        ORDER BY score DESC, date_created ASC
        LIMIT 10
    ");
    
    if (!$stmt) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'Query preparation failed'
        ]);
        return;
    }
    
    $stmt->execute();
    $result = $stmt->get_result();
    
    $scores = [];
    while ($row = $result->fetch_assoc()) {
        $scores[] = [
            'initials' => strtoupper($row['initials']),
            'score' => (int)$row['score'],
            'wave' => (int)$row['wave'],
            'date' => $row['date']
        ];
    }
    
    $stmt->close();
    
    echo json_encode([
        'success' => true,
        'scores' => $scores,
        'count' => count($scores)
    ]);
}

/**
 * Salva nuovo punteggio
 */
function saveScore($mysqli) {
    // Leggi JSON dal body
    $json = file_get_contents('php://input');
    $data = json_decode($json, true);
    
    if (!$data) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'Invalid JSON'
        ]);
        return;
    }
    
    // Validazione
    $initials = strtoupper(trim($data['initials'] ?? ''));
    $score = (int)($data['score'] ?? 0);
    $wave = (int)($data['wave'] ?? 1);
    $deviceId = trim($data['deviceId'] ?? '');
    
    if (strlen($initials) !== 3) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'Initials must be exactly 3 characters'
        ]);
        return;
    }
    
    if (!preg_match('/^[A-Z]{3}$/', $initials)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'Initials must contain only letters A-Z'
        ]);
        return;
    }
    
    if ($score <= 0) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'Score must be greater than 0'
        ]);
        return;
    }
    
    // Inserimento
    $stmt = $mysqli->prepare("
        INSERT INTO hiscores (player_initials, score, wave, device_id)
        VALUES (?, ?, ?, ?)
    ");
    
    if (!$stmt) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'Query preparation failed'
        ]);
        return;
    }
    
    $stmt->bind_param('siis', $initials, $score, $wave, $deviceId);
    
    if (!$stmt->execute()) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'Insert failed'
        ]);
        $stmt->close();
        return;
    }
    
    $insertId = $stmt->insert_id;
    $stmt->close();
    
    // Verifica se è entrato in top 10
    $stmtRank = $mysqli->prepare("
        SELECT COUNT(*) + 1 as rank
        FROM hiscores
        WHERE score > ? OR (score = ? AND date_created < (SELECT date_created FROM hiscores WHERE id = ?))
    ");
    $stmtRank->bind_param('iii', $score, $score, $insertId);
    $stmtRank->execute();
    $resultRank = $stmtRank->get_result();
    $rankRow = $resultRank->fetch_assoc();
    $rank = (int)$rankRow['rank'];
    $stmtRank->close();
    
    echo json_encode([
        'success' => true,
        'id' => $insertId,
        'rank' => $rank,
        'isTopTen' => $rank <= 10,
        'message' => $rank <= 10 ? 'Congratulations! You\'re in the top 10!' : 'Score saved successfully'
    ]);
}

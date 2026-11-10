(() => {
  const params = new URLSearchParams(location.search);
  const view = params.get('vista') || 'dashboard';
  const selectedId = params.get('id');
  const main = document.querySelector('main');
  const screenContent = main?.firstElementChild;
  const eventLabels = {
    partida_iniciada: 'Partida iniciada',
    partida_actualizada: 'Movimiento realizado',
    partida_finalizada: 'Partida finalizada',
    partida_caida: 'Caída de proceso OTP',
    partida_terminada: 'Partida terminada',
    jugador_en_espera: 'Jugador en matchmaking',
    jugador_retirado_de_espera: 'Jugador salió de la espera',
    jugadores_emparejados: 'Jugadores emparejados'
  };
  let latest = { admin: null, metrics: null, health: null, events: [] };
  let selectedEvent = null;
  let streaming = true;
  let refreshTimer;
  let socket;
  let socketRetry;
  if (screenContent) screenContent.hidden = true;

  function leafWithText(text, root = document) {
    return [...root.querySelectorAll('*')]
      .find(node => node.children.length === 0 && node.textContent.trim() === text);
  }

  function leafContaining(text, root = document) {
    return [...root.querySelectorAll('*')]
      .find(node => node.children.length === 0 &&
        node.textContent.trim().toLowerCase().includes(text.toLowerCase()));
  }

  function elementMatchingText(text, root, partial) {
    const target = text.toLowerCase();
    return [...root.querySelectorAll('*')]
      .filter(node => {
        const content = node.textContent.trim().toLowerCase();
        return partial ? content.includes(target) : content === target;
      })
      .sort((left, right) =>
        left.textContent.trim().length - right.textContent.trim().length
      )[0];
  }

  function replaceLeaf(oldText, newText, root = document) {
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    let node;
    while ((node = walker.nextNode())) {
      if (node.nodeValue.trim() !== oldText) continue;
      const leading = node.nodeValue.match(/^\s*/)[0];
      const trailing = node.nodeValue.match(/\s*$/)[0];
      node.nodeValue = `${leading}${newText}${trailing}`;
      return;
    }
    const element = elementMatchingText(oldText, root, false);
    if (element) element.textContent = newText;
  }

  function replaceContaining(oldText, newText, root = document) {
    const element = elementMatchingText(oldText, root, true);
    if (element) element.textContent = newText;
  }

  function replaceAllLeaves(oldText, newText, root = document) {
    [...root.querySelectorAll('*')]
      .filter(node => node.textContent.trim() === oldText)
      .filter(node => ![...node.querySelectorAll('*')]
        .some(child => child.textContent.trim() === oldText))
      .forEach(node => { node.textContent = newText; });
  }

  function replaceAllContaining(oldText, newText, root = document) {
    const target = oldText.toLowerCase();
    [...root.querySelectorAll('*')]
      .filter(node => node.textContent.trim().toLowerCase().includes(target))
      .filter(node => ![...node.querySelectorAll('*')]
        .some(child => child.textContent.trim().toLowerCase().includes(target)))
      .forEach(node => { node.textContent = newText; });
  }

  function setNextValue(labelText, value) {
    const label = leafWithText(labelText, main || document);
    if (label && label.nextElementSibling) {
      label.nextElementSibling.textContent = value;
    }
  }

  function addError(message) {
    if (view === 'detalle') {
      const toast = document.getElementById('status-toast');
      const text = document.getElementById('status-toast-text');
      if (toast && text) {
        text.textContent = message;
        toast.classList.remove('hidden');
      }
      return;
    }
    const target = main || document.body;
    let alert = document.getElementById('p17-live-error');
    if (!alert) {
      alert = document.createElement('p');
      alert.id = 'p17-live-error';
      alert.className = 'my-4 rounded-lg bg-secondary-container/30 p-3 text-secondary font-label-md';
      target.prepend(alert);
    }
    alert.textContent = message;
  }

  async function fetchJson(path) {
    const response = await fetch(path, { headers: { Accept: 'application/json' } });
    if (!response.ok) throw new Error(`${path}: HTTP ${response.status}`);
    return response.json();
  }

  function formatDuration(milliseconds) {
    if (!Number.isFinite(milliseconds)) return 'No disponible';
    const seconds = Math.floor(milliseconds / 1000);
    const minutes = Math.floor(seconds / 60);
    return minutes ? `${minutes}m ${seconds % 60}s` : `${seconds}s`;
  }

  function formatBytes(bytes) {
    if (!Number.isFinite(bytes)) return 'No disponible';
    const units = ['B', 'KB', 'MB', 'GB'];
    let amount = bytes;
    let unit = 0;
    while (amount >= 1024 && unit < units.length - 1) {
      amount /= 1024;
      unit++;
    }
    return `${amount.toFixed(unit ? 1 : 0)} ${units[unit]}`;
  }

  function gameUrl(id) {
    return `/admin?vista=detalle&id=${encodeURIComponent(id)}`;
  }

  function configureNavigation() {
    document.querySelectorAll('aside nav a').forEach(link => {
      const text = link.textContent.toLowerCase();
      if (text.includes('dashboard')) link.href = '/admin';
      else if (text.includes('detalle')) link.href = gameUrl(selectedId || '');
      else if (text.includes('bitácora')) link.href = '/admin?vista=eventos';
    });
    const breadcrumb = leafWithText('Partidas Activas', main || document);
    if (breadcrumb) {
      breadcrumb.addEventListener('click', () => { location.href = '/admin'; });
    }
    const headerButtons = [...document.querySelectorAll('header button')];
    const refresh = headerButtons.find(button =>
      button.textContent.toLowerCase().includes('refresh'));
    if (refresh) {
      refresh.setAttribute('aria-label', 'Actualizar datos');
      refresh.onclick = () => void refreshAll();
    }
    const notifications = headerButtons.find(button =>
      button.textContent.toLowerCase().includes('notifications'));
    if (notifications) {
      notifications.setAttribute('aria-label', 'Abrir bitácora de eventos');
      notifications.onclick = () => { location.href = '/admin?vista=eventos'; };
    }
  }

  function updateNodeChrome(health, metrics) {
    replaceContaining('CLUSTER BEAM V', 'Servidor Erlang/OTP');
    replaceContaining('Nodo online: p17@game-node-01',
      health.status === 'ok' ? 'Nodo online: P17' : 'Nodo no disponible');
    replaceLeaf('p17@game-node-01', 'P17 local');
    replaceLeaf('OTP 26.2', 'OTP activo');
    replaceLeaf('Ping: 12ms',
      health.status === 'ok' ? 'HTTP disponible' : 'HTTP no disponible');
    const processCount = leafWithText('BEAM Processes');
    if (processCount?.nextElementSibling) {
      processCount.nextElementSibling.textContent =
        String(metrics.diagnostico.procesos);
    }
    replaceLeaf('Schedulers Online', 'Run queue');
    const runQueue = leafWithText('Run queue');
    if (runQueue?.nextElementSibling) {
      runQueue.nextElementSibling.textContent =
        String(metrics.diagnostico.run_queue);
    }
  }

  function describeEvent(event) {
    if (event.jugador) return `Jugador: ${event.jugador}`;
    if (Array.isArray(event.jugadores)) return `Jugadores: ${event.jugadores.join(' vs ')}`;
    if (event.partida && Array.isArray(event.partida.jugadores)) {
      return `Jugadores: ${event.partida.jugadores.join(' vs ')}`;
    }
    if (event.id) return `Partida #${event.id}`;
    return 'Servidor P17';
  }

  function eventTitle(event) {
    return eventLabels[event.evento] || event.evento || 'Evento del servidor';
  }

  function eventTime(event) {
    if (!Number.isFinite(event.timestamp_ms)) return 'Hora no disponible';
    return new Date(event.timestamp_ms).toLocaleString('es-MX');
  }

  function severityLabel(severity) {
    if (severity === 'error') return 'Crítico';
    if (severity === 'warning') return 'Advertencia';
    return 'Info';
  }

  function eventSearchText(event) {
    return [
      event.id,
      event.jugador,
      ...(event.jugadores || []),
      event.evento,
      JSON.stringify(event.partida || {})
    ].filter(Boolean).join(' ').toLowerCase();
  }

  function createCell(row, text, className = '') {
    const cell = document.createElement('td');
    cell.className = className;
    cell.textContent = text;
    row.append(cell);
    return cell;
  }

  function replaceRecentEvents(events) {
    const heading = leafWithText('Actividad & Alertas', main || document);
    if (!heading) return;
    const panel = heading.parentElement.parentElement.parentElement
      .querySelector('.bg-surface-container-low.rounded-xl');
    if (!panel) return;
    panel.replaceChildren();
    const queue = document.createElement('section');
    queue.className = 'mb-3 rounded-lg bg-surface-container p-3';
    const queueTitle = document.createElement('h3');
    queueTitle.className = 'mb-2 text-on-surface font-label-md font-bold';
    queueTitle.textContent = `Jugadores en espera (${latest.admin.jugadores_en_espera.length})`;
    queue.append(queueTitle);
    if (!latest.admin.jugadores_en_espera.length) {
      const emptyQueue = document.createElement('p');
      emptyQueue.className = 'text-on-surface-variant font-body-md';
      emptyQueue.textContent = 'No hay jugadores en espera.';
      queue.append(emptyQueue);
    } else {
      const queueList = document.createElement('ul');
      queueList.className = 'flex flex-col gap-1';
      latest.admin.jugadores_en_espera.forEach(name => {
        const player = document.createElement('li');
        player.className = 'text-on-surface font-body-md';
        player.textContent = name;
        queueList.append(player);
      });
      queue.append(queueList);
    }
    panel.append(queue);
    const list = document.createElement('div');
    list.className = 'flex flex-col gap-2';
    const recent = events.slice(0, 5);
    if (!recent.length) {
      const empty = document.createElement('p');
      empty.className = 'text-on-surface-variant font-body-md';
      empty.textContent = 'No hay eventos registrados todavía.';
      list.append(empty);
    }
    recent.forEach(event => {
      const item = document.createElement('article');
      item.className = 'rounded-lg bg-surface-container p-3 flex flex-col gap-1';
      const title = document.createElement('strong');
      title.className = event.severidad === 'error'
        ? 'text-secondary font-label-md'
        : 'text-primary font-label-md';
      title.textContent = `${severityLabel(event.severidad)} · ${eventTitle(event)}`;
      const detail = document.createElement('p');
      detail.className = 'text-on-surface-variant font-body-md';
      detail.textContent = `${describeEvent(event)} · ${eventTime(event)}`;
      item.append(title, detail);
      list.append(item);
    });
    panel.append(list);
  }

  function renderDashboard() {
    const { admin, metrics, health, events } = latest;
    setNextValue('Partidas Activas', String(admin.partidas_activas));
    setNextValue('En Cola / Matchmaking', String(admin.cantidad_en_espera));
    setNextValue('Duración Promedio', formatDuration(admin.duracion_promedio_ms));
    replaceLeaf('Uptime Supervisores', 'Salud del servidor', main);
    setNextValue('Salud del servidor', health.status === 'ok' ? 'Disponible' : 'No disponible');
    replaceLeaf('Capacidad de sesiones', 'Estado de partidas', main);
    replaceLeaf('0.6% de carga', `${admin.partidas_activas} activas`, main);
    replaceLeaf('1.8 segundos', 'No medido por el backend', main);
    replaceLeaf('3.4 s / turno', 'No medido por el backend', main);
    replaceLeaf('Tiempo medio en espera', 'Espera promedio', main);
    replaceLeaf('Ritmo de jugada', 'Ritmo de jugada', main);
    replaceLeaf('OTP 26.2', 'OTP activo', main);
    replaceContaining('CLUSTER BEAM V', 'Servidor Erlang/OTP', main);
    replaceLeaf('p17@game-node-01', 'P17 local', document);
    replaceLeaf('Ping: 12ms', 'HTTP disponible', document);
    replaceLeaf('BEAM Schedulers: 16/16 Online',
      `Procesos BEAM: ${metrics.diagnostico.procesos}`, main);
    replaceLeaf('Nodo: p17@game-cluster-01', 'Nodo: servidor local', main);
    replaceLeaf('Nodo online: p17@game-node-01',
      health.status === 'ok' ? 'Nodo online: P17' : 'Nodo no disponible', main);
    replaceLeaf('Sincronización socket ETS', 'Actualización por WebSocket', main);
    replaceLeaf('18 ms ping medio', `${events.length} eventos recientes`, main);
    replaceLeaf('142 MB', formatBytes(metrics.diagnostico.memoria_usada_bytes), main);
    replaceLeaf('1,420', String(metrics.diagnostico.procesos), main);
    replaceLeaf('/ 262k', `/ ${metrics.diagnostico.limite_procesos}`, main);
    replaceLeaf('Estrategia Global: rest_for_one',
      'Estrategia Global: one_for_one', main);
    replaceLeaf('P17.GameSupervisor', 'p17_partidas_sup', main);
    replaceLeaf('Estrategia: one_for_all', 'Reinicio: temporary', main);
    replaceLeaf('Intensidad: 5 reinicios / 60s',
      `${admin.partidas_activas} partidas activas`, main);
    replaceLeaf('P17.Matchmaking', 'p17_matchmaking', main);
    replaceContaining('Cola ETS: 2 entradas',
      `Jugadores en espera: ${admin.cantidad_en_espera}`, main);
    replaceLeaf('P17.SessionRegistry', 'p17_eventos', main);
    replaceContaining('Tipo: Distributed ETS', 'Historial: memoria local', main);
    replaceContaining('Registros: 3 PIDs vinculados',
      `${events.length} de 200 eventos`, main);
    replaceContaining('Estables', `${admin.partidas_activas} partidas activas`, main);
    replaceAllContaining('Auto-reparada',
      `${admin.partidas_caidas} caídas registradas`, main);
    replaceLeaf('142 MB / 4 GB',
      formatBytes(metrics.diagnostico.memoria_usada_bytes), main);
    replaceLeaf('Procesos: 48 MB', 'Desglose no expuesto', main);
    replaceLeaf('ETS Tables: 32 MB', 'Desglose no expuesto', main);
    replaceLeaf('Código / Binarios: 16 MB', 'Desglose no expuesto', main);
    const matchSummary = [...main.querySelectorAll('span,div,p')]
      .find(node => node.children.length === 0 &&
        node.textContent.includes('Mostrando 3 de 3 partidas concurrentes'));
    if (matchSummary) {
      matchSummary.textContent =
        `Mostrando ${admin.partidas_activas} de ${admin.partidas_activas} partidas activas`;
    }

    const gcButton = [...document.querySelectorAll('button')]
      .find(button => button.textContent.includes('Forzar Recolección de Basura'));
    if (gcButton) {
      gcButton.disabled = true;
      gcButton.title = 'El backend no expone esta operación.';
      gcButton.setAttribute('aria-label', 'Operación no disponible: recolección de basura');
    }

    const body = main.querySelector('table tbody');
    if (body) {
      body.replaceChildren();
      if (!admin.partidas.length) {
        const row = document.createElement('tr');
        const cell = createCell(row, 'No hay partidas activas.');
        cell.colSpan = 7;
        cell.className = 'px-4 py-6 text-center text-on-surface-variant';
        body.append(row);
      }
      admin.partidas.forEach(game => {
        const row = document.createElement('tr');
        row.className = 'hover:bg-surface-container-high/40 transition-colors';
        const idCell = createCell(row, `#${game.id}\n${game.pid}`, 'py-3 px-4 font-mono whitespace-pre-line');
        idCell.classList.add('text-primary');
        createCell(row, (game.datos.jugadores || []).join(' vs '), 'py-3 px-4');
        createCell(row,
          `Turno: ${game.datos.turno}\n${(game.datos.tablero || []).filter(cell => cell !== 'vacio').length} movimientos`,
          'py-3 px-4 whitespace-pre-line');
        createCell(row, formatDuration(game.duracion_ms), 'py-3 px-4 font-mono');
        createCell(row, game.estado, 'py-3 px-4 text-tertiary font-mono');
        createCell(row, 'Saludable', 'py-3 px-4 text-tertiary');
        const actionCell = createCell(row, '', 'py-3 px-4 text-right');
        const action = document.createElement('a');
        action.className = 'inline-flex items-center gap-1 px-3 py-1.5 rounded bg-surface-container-high text-primary hover:bg-primary-container font-label-md';
        action.href = gameUrl(game.id);
        action.textContent = 'Ver detalle';
        actionCell.append(action);
        body.append(row);
      });
    }

    const sessionCount = leafWithText('3 sesiones', main);
    if (sessionCount) sessionCount.textContent = `${admin.partidas_activas} sesiones`;
    replaceRecentEvents(events);
    const updateTime = new Date().toLocaleTimeString('es-MX');
    replaceLeaf('Última actualización', updateTime, main);
    latest.events = events;
  }

  function renderDetail(admin, metrics, game) {
    const data = game.datos;
    const players = data.jugadores || [];
    const board = data.tablero || [];
    const letters = new Map([[players[0], 'X'], [players[1], 'O']]);
    const h1 = main.querySelector('h1');
    if (h1) h1.textContent = `Partida #${game.id}`;
    replaceLeaf('gen_statem: en_curso', `gen_statem: ${game.estado}`, main);
    replaceLeaf('OTP: Saludable', 'Proceso disponible', main);
    replaceLeaf('P17.GameSupervisor', 'p17_partidas_sup', main);
    const pid = main.querySelector('.text-tertiary-fixed');
    if (pid) pid.textContent = game.pid;
    replaceLeaf('Turno #5', `Turno: ${data.turno}`, main);
    const turnMark = letters.get(data.turno);
    replaceLeaf('Ana (Ficha X)',
      `${data.turno} (Ficha ${turnMark || 'activa'})`, main);

    const cells = [...main.querySelectorAll('[class*="grid-cols-3"]')]
      .find(grid => grid.children.length === 9);
    if (cells) {
      [...cells.children].forEach((cell, index) => {
        cell.replaceChildren();
        const name = board[index];
        if (name && name !== 'vacio') {
          const mark = document.createElement('span');
          mark.className = `font-display-lg text-display-lg select-none font-bold ${letters.get(name) === 'X' ? 'text-secondary' : 'text-tertiary'}`;
          mark.textContent = letters.get(name) || name;
          cell.append(mark);
        }
        const number = document.createElement('span');
        number.className = 'absolute top-1 left-1.5 font-mono text-[10px] text-outline';
        number.textContent = String(index + 1);
        cell.append(number);
        cell.classList.remove('cursor-pointer', 'hover:bg-surface-bright');
      });
    }

    const turnText = leafWithText('Casilla recomendada/esperada: 9', main);
    if (turnText) turnText.textContent = `Turno actual: ${data.turno}`;
    const durationLabel = [...main.querySelectorAll('span')]
      .find(node => node.textContent.trim().startsWith('Duración:'));
    const durationValue = durationLabel?.querySelector('strong');
    if (durationValue) durationValue.textContent = formatDuration(game.duracion_ms);
    const timer = document.getElementById('turn-timer');
    if (timer?.parentElement?.parentElement) {
      timer.parentElement.parentElement.classList.add('hidden');
    }

    const staticNames = [...main.querySelectorAll('*')]
      .filter(node => node.children.length === 0 &&
        ['Ana López', 'Carlos Mendoza'].includes(node.textContent.trim()));
    staticNames.forEach((node, index) => {
      node.textContent = players[index] || 'Jugador no disponible';
    });
    replaceAllContaining('IP:', 'Identificador individual no expuesto', main);
    replaceAllContaining('Latencia:', 'Latencia no expuesta', main);
    replaceAllContaining('Pid Handler:', 'Proceso individual no expuesto', main);
    replaceAllContaining('Frame In/Out:', 'Canal global: /ws/juego', main);
    replaceContaining('Supervisor: P17.GameSupervisor',
      'Supervisor: p17_partidas_sup', main);
    replaceLeaf('Partida #4892', `Partida #${game.id}`, main);
    replaceLeaf('Canales WebSockets', 'Jugadores de la partida', main);
    replaceLeaf('Cowboy WS Protocol', 'Datos disponibles vía API', main);
    replaceAllLeaves('Socket Activo', 'Jugador registrado', main);
    replaceLeaf('Auth: Nivel Operador L2', 'Modo: solo lectura', main);
    replaceLeaf('Mnesia Checkpointer Sync',
      'Datos actuales de la partida', main);
    replaceLeaf('DISC_COPIES: OK', 'Origen: API del servidor', main);
    replaceLeaf('hace 4s', 'consulta en vivo', main);
    replaceContaining('Último commit:', 'Consulta:', main);
    replaceLeaf('SysTrace Activo', `${latest.events.length} eventos del nodo`, main);
    replaceLeaf('Bitácora de Transiciones (OTP Trace)',
      'Eventos de partida', main);
    replaceLeaf('Inspección de Proceso Erlang/OTP',
      'Diagnóstico del nodo Erlang/OTP', main);
    replaceLeaf('erlang:process_info/2', 'Métricas VM / Recon', main);
    const stateData = [...main.querySelectorAll('div')]
      .find(node => node.classList.contains('overflow-x-auto') &&
        node.textContent.includes('state_data:'));
    if (stateData) {
      stateData.textContent =
        `Respuesta GET /api/partidas/${game.id}: ${JSON.stringify(game)}`;
    }
    const timelineHeading = leafWithText('Eventos de partida', main);
    const timeline = timelineHeading?.parentElement?.parentElement?.parentElement;
    if (timeline) {
      const eventList = timeline.querySelector('.flex.flex-col.gap-2');
      const gameEvents = latest.events.filter(event => String(event.id) === String(game.id));
      if (eventList) {
        eventList.replaceChildren();
        gameEvents.forEach(event => {
          const item = document.createElement('div');
          item.className = 'flex items-start gap-3 p-space-sm bg-surface-container rounded-lg';
          const time = document.createElement('span');
          time.className = 'font-mono text-label-md text-outline';
          time.textContent = eventTime(event);
          const dot = document.createElement('span');
          dot.className = 'w-2 h-2 rounded-full bg-primary mt-1.5';
          const details = document.createElement('div');
          details.className = 'flex flex-col flex-1 min-w-0';
          const title = document.createElement('span');
          title.className = 'font-label-lg text-on-surface';
          title.textContent = eventTitle(event);
          const description = document.createElement('span');
          description.className = 'font-mono text-label-md text-on-surface-variant';
          description.textContent = describeEvent(event);
          details.append(title, description);
          item.append(time, dot, details);
          eventList.append(item);
        });
        if (!gameEvents.length) {
          const empty = document.createElement('p');
          empty.className = 'text-on-surface-variant';
          empty.textContent = 'No hay eventos de esta partida en el historial reciente.';
          eventList.append(empty);
        }
      }
    }

    const diagLabels = [
      ['Memoria Heap', 'Memoria VM', formatBytes(metrics.diagnostico.memoria_usada_bytes)],
      ['Reductions OTP', 'Procesos BEAM',
        `${metrics.diagnostico.procesos} / ${metrics.diagnostico.limite_procesos}`],
      ['Cola de Mensajes', 'Run queue', String(metrics.diagnostico.run_queue)],
      ['Supervisor Link', 'Partidas activas', String(admin.partidas_activas)]
    ];
    diagLabels.forEach(([oldLabel, label, value]) => {
      const node = leafWithText(oldLabel, main);
      if (!node) return;
      node.textContent = label;
      const valueNode = node.parentElement.querySelector('.font-headline-sm, .font-title-md');
      if (valueNode) valueNode.textContent = value;
      const extra = node.parentElement.querySelector('.mt-1');
      if (extra) extra.textContent = 'Dato reportado por el nodo Erlang/OTP';
    });

    const operationsHeading = leafWithText('Operaciones Administrativas del Proceso', main);
    if (operationsHeading) operationsHeading.textContent = 'Operaciones no expuestas por la API';
    const operationsDescription = [...main.querySelectorAll('span,p')]
      .find(node => node.textContent.includes('Comandos de supervisión y gestión directa'));
    if (operationsDescription) {
      operationsDescription.textContent =
        'El servidor actual expone consultas y movimientos; no ofrece comandos administrativos destructivos.';
    }
    ['btn-force-sync', 'btn-pause-game', 'btn-restart-process', 'btn-kill-game']
      .forEach(id => {
        const button = document.getElementById(id);
        if (button) {
          button.disabled = true;
          button.title = 'No disponible: el backend no expone esta operación.';
        }
      });
    const quickRefresh = document.getElementById('btn-quick-refresh');
    if (quickRefresh) quickRefresh.onclick = () => void refreshAll();
  }

  function renderEvents(events) {
    const timeFilter = document.getElementById('filter-time');
    const typeFilter = document.getElementById('filter-type');
    const severityFilter = document.getElementById('filter-severity');
    const search = (document.getElementById('search-pid')?.value || '').trim().toLowerCase();
    const cutoff = timeFilter ? [
      Date.now() - 24 * 60 * 60 * 1000,
      new Date().setHours(0, 0, 0, 0),
      Date.now() - 6 * 60 * 60 * 1000,
      Date.now() - 60 * 60 * 1000,
      0
    ][timeFilter.selectedIndex] : 0;
    const type = typeFilter?.value || '';
    const severity = severityFilter?.value || '';
    const visible = events.filter(event =>
      (!cutoff || (Number.isFinite(event.timestamp_ms) && event.timestamp_ms >= cutoff)) &&
      (!type || type === event.evento) &&
      (!severity || severity === event.severidad) &&
      (!search || eventSearchText(event).includes(search))
    );
    latest.visibleEvents = visible;
    const body = document.getElementById('events-table-body');
    if (body) {
      body.replaceChildren();
      visible.forEach(event => {
        const row = document.createElement('tr');
        row.className = 'event-row cursor-pointer transition-colors hover:bg-surface-container group';
        row.dataset.eventId = event.id || '';
        createCell(row, eventTime(event), 'py-3.5 px-space-md font-mono text-label-md');
        createCell(row, severityLabel(event.severidad), 'py-3.5 px-space-sm');
        createCell(row, eventTitle(event), 'py-3.5 px-space-md');
        createCell(row, event.id ? `#${event.id}` : '—', 'py-3.5 px-space-md font-mono text-primary');
        createCell(row, describeEvent(event), 'py-3.5 px-space-md text-on-surface-variant');
        createCell(row,
          event.severidad === 'error' ? 'Caída registrada' :
            event.severidad === 'warning' ? 'Revisar' : 'Registrado',
          'py-3.5 px-space-md text-right');
        row.addEventListener('click', () => showEvent(event));
        body.append(row);
      });
      if (!visible.length) {
        const row = document.createElement('tr');
        const cell = createCell(row, 'No hay eventos que coincidan con los filtros.');
        cell.colSpan = 6;
        cell.className = 'p-6 text-center text-on-surface-variant';
        body.append(row);
      }
    }
    const mobile = document.getElementById('events-mobile-list');
    if (mobile) {
      mobile.replaceChildren();
      visible.forEach(event => {
        const item = document.createElement('button');
        item.type = 'button';
        item.className = 'event-mobile-card w-full text-left bg-surface-container p-space-md rounded-lg flex flex-col gap-2';
        const title = document.createElement('strong');
        title.textContent = `${severityLabel(event.severidad)} · ${eventTitle(event)}`;
        const detail = document.createElement('span');
        detail.textContent = `${describeEvent(event)} · ${eventTime(event)}`;
        item.append(title, detail);
        item.addEventListener('click', () => showEvent(event));
        mobile.append(item);
      });
    }
    const count = document.getElementById('filtered-count');
    if (count) count.textContent = `${visible.length} eventos`;
    replaceLeaf('3.4 ms', 'No medido', main);
    replaceLeaf('512 / 10,000 entradas', `${events.length} / 200 eventos`, main);
    replaceContaining('77.1% del volumen total', 'Conteo del historial real', main);
    replaceContaining('Resuelto vía Supervisor',
      'No se asume autorrecuperación', main);
    replaceLeaf('0 pérdidas de estado Mnesia',
      'Mnesia no está configurada en este servidor', main);
    replaceContaining('jornada anterior', 'Historial volátil del nodo', main);
    replaceContaining('Buffer en memoria:',
      `${events.length} / 200 eventos en memoria`, main);
    replaceContaining('Latencia de ingesta promedio:',
      'Latencia de ingesta:', main);
    replaceContaining('Tasa: ~28 ev/min', 'Tasa no medida', main);
    replaceContaining('~28 ev/min', 'Tasa no medida', main);
    replaceContaining('0 pérdidas de estado Mnesia',
      'Mnesia no está configurada en este servidor', main);
    const pagination = [...main.querySelectorAll('button')]
      .filter(button => ['chevron_left', 'chevron_right'].includes(button.textContent.trim()));
    pagination.forEach(button => {
      button.disabled = true;
      button.title = 'El API devuelve hasta 200 eventos en una sola página.';
    });
    if (!selectedEvent && visible.length) showEvent(visible[0]);
    if (!visible.length && !selectedEvent) {
      document.getElementById('inspector-panel')?.classList.add('hidden');
    }
    updateEventSummary(events);
  }

  function updateEventSummary(events) {
    const updates = [
      ['Total Eventos (24h)', 'Eventos en historial', String(events.length)],
      ['Jugadas Registradas', 'Movimientos registrados',
        String(events.filter(event => event.evento === 'partida_actualizada').length)],
      ['Caídas OTP Recuperadas', 'Caídas registradas',
        String(events.filter(event => event.evento === 'partida_caida').length)],
      ['Tasa de Autorrecuperación', 'Recuperación automática', 'No disponible']
    ];
    updates.forEach(([oldLabel, newLabel, value]) => {
      const label = leafWithText(oldLabel, main);
      if (!label) return;
      label.textContent = newLabel;
      const card = label.parentElement;
      const valueNode = card.querySelector('.font-display-lg, .font-headline-lg');
      if (valueNode) valueNode.textContent = value;
      const note = card.querySelector('.font-label-md, .text-on-surface-variant');
      if (note && note !== label && note !== valueNode) {
        note.textContent = 'Historial en memoria del nodo (máx. 200)';
      }
    });
  }

  function showEvent(event) {
    selectedEvent = event;
    const inspector = document.getElementById('inspector-panel');
    if (inspector) inspector.classList.remove('hidden');
    const timestamp = document.getElementById('detail-timestamp');
    const pid = document.getElementById('detail-pid');
    const module = document.getElementById('detail-module');
    const description = document.getElementById('detail-description');
    const raw = document.getElementById('detail-raw');
    const badge = document.getElementById('inspector-badge');
    if (timestamp) timestamp.textContent = eventTime(event);
    if (pid) pid.textContent = event.id ? `#${event.id}` : 'Servidor P17';
    if (module) module.textContent = event.evento || 'Evento del servidor';
    if (description) description.textContent = `${eventTitle(event)}. ${describeEvent(event)}`;
    if (raw) raw.textContent = JSON.stringify(event, null, 2);
    if (badge) badge.textContent = severityLabel(event.severidad);
    replaceAllLeaves('P17.GameSupervisor', 'p17_servidor_de_juego_sup', main);
    replaceAllLeaves('one_for_one (transient)',
      'one_for_one; partida temporary', main);
  }

  function configureEventTypeOptions() {
    const type = document.getElementById('filter-type');
    if (!type) return;
    const previous = type.value;
    const types = [...new Set(latest.events.map(event => event.evento).filter(Boolean))];
    type.replaceChildren(new Option('Todos los tipos', ''));
    types.forEach(name => type.add(new Option(eventTitle({ evento: name }), name)));
    if (types.includes(previous)) type.value = previous;
  }

  function configureEvents() {
    document.getElementById('inspector-panel')?.classList.add('hidden');
    const type = document.getElementById('filter-type');
    if (type) {
      configureEventTypeOptions();
      type.addEventListener('change', () => renderEvents(latest.events));
    }
    const severity = document.getElementById('filter-severity');
    if (severity) {
      severity.replaceChildren(
        new Option('Todas las severidades', ''),
        new Option('Info', 'info'),
        new Option('Advertencia', 'warning'),
        new Option('Crítico', 'error')
      );
      severity.addEventListener('change', () => renderEvents(latest.events));
    }
    ['filter-time', 'search-pid'].forEach(id => {
      document.getElementById(id)?.addEventListener('input', () => renderEvents(latest.events));
    });
    window.applyFilters = () => renderEvents(latest.events);
    window.resetFilters = () => {
      ['filter-time', 'search-pid', 'filter-type', 'filter-severity']
        .forEach(id => {
          const control = document.getElementById(id);
          if (control) control.selectedIndex = 0;
          if (control && control.tagName === 'INPUT') control.value = '';
        });
      renderEvents(latest.events);
    };
    window.selectEvent = index => showEvent(latest.events[index]);
    window.copyRawPayload = async () => {
      const payload = document.getElementById('detail-raw')?.textContent || '';
      try {
        await navigator.clipboard.writeText(payload);
      } catch (error) {
        addError(`No se pudo copiar el evento: ${error.message}`);
      }
    };
    window.toggleExportMenu = () => {
      document.getElementById('export-dropdown')?.classList.toggle('hidden');
    };
    window.toggleStream = () => {
      streaming = !streaming;
      const label = document.getElementById('streaming-label');
      const text = document.getElementById('stream-btn-text');
      const icon = document.getElementById('stream-icon');
      if (label) label.textContent = streaming ? 'Streaming en vivo' : 'Flujo pausado';
      if (text) text.textContent = streaming ? 'Pausar flujo' : 'Reanudar flujo';
      if (icon) icon.textContent = streaming ? 'pause_circle' : 'play_circle';
      if (streaming) renderEvents(latest.events);
    };
    document.querySelectorAll('#export-dropdown a').forEach(link => {
      link.onclick = event => {
        event.preventDefault();
        const csv = link.textContent.toLowerCase().includes('csv');
        downloadEvents(csv);
        document.getElementById('export-dropdown')?.classList.add('hidden');
      };
    });
    const reset = [...main.querySelectorAll('button')]
      .find(button => button.textContent.includes('Restablecer filtros'));
    if (reset) reset.onclick = window.resetFilters;
    const inspectSupervisor = [...main.querySelectorAll('button')]
      .find(button => button.textContent.includes('Inspeccionar Árbol OTP'));
    if (inspectSupervisor) {
      inspectSupervisor.onclick = () => { location.href = '/admin'; };
    }
    const validateMnesia = [...main.querySelectorAll('button')]
      .find(button => button.title.includes('Validar Integridad'));
    if (validateMnesia) {
      validateMnesia.disabled = true;
      validateMnesia.title = 'Mnesia no está configurada en este servidor.';
    }
    const customRange = document.getElementById('filter-time')?.options[4];
    if (customRange) {
      customRange.disabled = true;
      customRange.textContent = 'Personalizado (no disponible)';
    }
  }

  function downloadEvents(csv) {
    const events = latest.visibleEvents || latest.events;
    const content = csv
      ? [
          ['timestamp', 'severity', 'event', 'game_id', 'description'],
          ...events.map(event => [
            event.timestamp_ms ? new Date(event.timestamp_ms).toISOString() : '',
            event.severidad || '',
            event.evento || '',
            event.id || '',
            describeEvent(event)
          ])
        ].map(row => row.map(value => `"${String(value).replaceAll('"', '""')}"`).join(',')).join('\r\n')
      : JSON.stringify({ total: events.length, eventos: events }, null, 2);
    const blob = new Blob([content], { type: csv ? 'text/csv;charset=utf-8' : 'application/json;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement('a');
    anchor.href = url;
    anchor.download = csv ? 'p17-eventos.csv' : 'p17-eventos.json';
    anchor.click();
    URL.revokeObjectURL(url);
  }

  async function loadSnapshot() {
    const [admin, metrics, health, eventResponse] = await Promise.all([
      fetchJson('/api/admin'),
      fetchJson('/metrics'),
      fetchJson('/health'),
      fetchJson('/api/admin/eventos')
    ]);
    latest = { admin, metrics, health, events: eventResponse.eventos };
    updateNodeChrome(health, metrics);
    if (view === 'dashboard') {
      renderDashboard();
    } else if (view === 'eventos') {
      configureEventTypeOptions();
      renderEvents(latest.events);
    } else if (view === 'detalle') {
      const id = selectedId || admin.partidas[0]?.id;
      if (!id) {
        addError('No hay partidas activas para inspeccionar. Regresa al dashboard para ver el estado del servidor.');
        return;
      }
      const game = admin.partidas.find(item => String(item.id) === id);
      if (!game) {
        await fetchJson(`/api/partidas/${encodeURIComponent(id)}`);
        return;
      }
      renderDetail(admin, metrics, game);
    }
    if (screenContent) screenContent.hidden = false;
    document.getElementById('p17-live-error')?.remove();
  }

  async function refreshAll() {
    try {
      await loadSnapshot();
    } catch (error) {
      addError(`No se pudieron cargar datos del servidor: ${error.message}`);
    }
  }

  function connectRealtime() {
    const scheme = location.protocol === 'https:' ? 'wss:' : 'ws:';
    socket = new WebSocket(`${scheme}//${location.host}/ws/juego`);
    socket.addEventListener('message', () => void refreshAll());
    socket.addEventListener('error', () => {
      const status = document.getElementById('streaming-label');
      if (status) status.textContent = 'WebSocket desconectado; se reintentará';
    });
    socket.addEventListener('close', () => {
      clearTimeout(socketRetry);
      socketRetry = setTimeout(connectRealtime, 3000);
    });
  }

  configureNavigation();
  if (view === 'detalle') {
    document.querySelectorAll('[id^="btn-"]').forEach(button => {
      if (button.id !== 'btn-quick-refresh') {
        button.disabled = true;
        button.title = 'No disponible: el backend no expone esta operación.';
      }
    });
  }
  if (view === 'eventos') configureEvents();
  void refreshAll();
  refreshTimer = setInterval(() => {
    if (view !== 'eventos' || streaming) void refreshAll();
  }, 10000);
  connectRealtime();
  window.addEventListener('beforeunload', () => {
    clearInterval(refreshTimer);
    clearTimeout(socketRetry);
    if (socket) socket.close();
  });
})();

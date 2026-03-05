-- =====================================================
-- PvP Rooms & Answers
-- =====================================================

-- pvp_rooms: tracks each PvP match
create table if not exists public.pvp_rooms (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references public.users(id) on delete cascade,
  guest_id uuid references public.users(id) on delete set null,
  status text not null default 'waiting', -- 'waiting', 'accepted', 'playing', 'finished'
  host_ready boolean default false,
  guest_ready boolean default false,
  host_score int default 0,
  guest_score int default 0,
  current_question int default 0,
  total_questions int default 10,
  winner_id uuid references public.users(id) on delete set null,
  created_at timestamptz default now(),
  started_at timestamptz,
  finished_at timestamptz
);

-- pvp_answers: tracks each player's answer per question
create table if not exists public.pvp_answers (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.pvp_rooms(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  question_id uuid not null references public.quiz_questions(id) on delete cascade,
  question_index int not null,
  answer text, -- 'A', 'B', 'C', 'D'
  is_correct boolean default false,
  answered_at timestamptz default now()
);

-- pvp_room_questions: stores the question set for each room
create table if not exists public.pvp_room_questions (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.pvp_rooms(id) on delete cascade,
  question_id uuid not null references public.quiz_questions(id) on delete cascade,
  question_index int not null
);

-- Indexes
create index if not exists idx_pvp_rooms_host on public.pvp_rooms(host_id);
create index if not exists idx_pvp_rooms_guest on public.pvp_rooms(guest_id);
create index if not exists idx_pvp_rooms_status on public.pvp_rooms(status);
create index if not exists idx_pvp_answers_room on public.pvp_answers(room_id);
create index if not exists idx_pvp_room_questions_room on public.pvp_room_questions(room_id, question_index);

-- RLS
alter table public.pvp_rooms enable row level security;
alter table public.pvp_answers enable row level security;
alter table public.pvp_room_questions enable row level security;

-- pvp_rooms: participants can read, host can create, participants can update
create policy "PvP room participants can read" on public.pvp_rooms
  for select using (auth.uid() = host_id or auth.uid() = guest_id);

create policy "Authenticated users can read rooms they are invited to" on public.pvp_rooms
  for select using (auth.role() = 'authenticated');

create policy "Users can create PvP rooms" on public.pvp_rooms
  for insert with check (auth.uid() = host_id);

create policy "Participants can update PvP rooms" on public.pvp_rooms
  for update using (auth.uid() = host_id or auth.uid() = guest_id);

-- pvp_answers: participants can read and insert
create policy "PvP answer participants can read" on public.pvp_answers
  for select using (
    exists (
      select 1 from public.pvp_rooms r
      where r.id = room_id and (r.host_id = auth.uid() or r.guest_id = auth.uid())
    )
  );

create policy "Users can insert own PvP answers" on public.pvp_answers
  for insert with check (auth.uid() = user_id);

-- pvp_room_questions: participants can read, host can insert
create policy "PvP room question participants can read" on public.pvp_room_questions
  for select using (
    exists (
      select 1 from public.pvp_rooms r
      where r.id = room_id and (r.host_id = auth.uid() or r.guest_id = auth.uid())
    )
  );

create policy "Host can insert room questions" on public.pvp_room_questions
  for insert with check (
    exists (
      select 1 from public.pvp_rooms r
      where r.id = room_id and r.host_id = auth.uid()
    )
  );

-- Enable Realtime for pvp_rooms
alter publication supabase_realtime add table public.pvp_rooms;

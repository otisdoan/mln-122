-- =====================================================
-- MLN-122: Initial Schema Migration
-- Run this in Supabase SQL Editor
-- =====================================================

-- 1. USERS TABLE
-- Extends Supabase auth.users with app-specific profile data
create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  username text not null,
  avatar text default '',
  xp integer default 0,
  level integer default 1,
  created_at timestamptz default now()
);

-- 2. LESSONS TABLE
create table if not exists public.lessons (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text default '',
  icon_name text default 'book',
  duration text default '15 phút đọc',
  is_locked boolean default false,
  content text default '',
  formula text default '',
  order_index integer default 0,
  created_at timestamptz default now()
);

-- 3. USER_LESSONS (join table)
create table if not exists public.user_lessons (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  completed boolean default false,
  completed_at timestamptz,
  unique(user_id, lesson_id)
);

-- 4. QUIZ_QUESTIONS TABLE
create table if not exists public.quiz_questions (
  id uuid primary key default gen_random_uuid(),
  question text not null,
  option_a text not null,
  option_b text not null,
  option_c text not null,
  option_d text not null,
  correct_answer text not null, -- 'A', 'B', 'C', or 'D'
  difficulty text default 'basic',
  topic text default 'general',
  created_at timestamptz default now()
);

-- 5. QUIZ_SETS TABLE
create table if not exists public.quiz_sets (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  difficulty text default 'basic',
  question_count integer default 10,
  created_at timestamptz default now()
);

-- 6. QUIZ_SET_QUESTIONS (join table)
create table if not exists public.quiz_set_questions (
  id uuid primary key default gen_random_uuid(),
  set_id uuid not null references public.quiz_sets(id) on delete cascade,
  question_id uuid not null references public.quiz_questions(id) on delete cascade,
  unique(set_id, question_id)
);

-- 7. QUIZ_RESULTS TABLE
create table if not exists public.quiz_results (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  score integer not null default 0,
  total_questions integer not null default 0,
  time_taken_seconds integer default 0,
  set_id uuid references public.quiz_sets(id) on delete set null,
  created_at timestamptz default now()
);

-- 8. SIMULATIONS TABLE
create table if not exists public.simulations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  capital_constant double precision default 1200000,
  capital_variable double precision default 450000,
  workers integer default 50,
  machines integer default 12,
  technology_level integer default 1,
  working_hours integer default 8,
  profit double precision default 0,
  surplus_value double precision default 0,
  created_at timestamptz default now()
);

-- 9. LEADERBOARD TABLE
create table if not exists public.leaderboard (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  score integer default 0,
  season text not null default 'all',
  updated_at timestamptz default now(),
  unique(user_id, season)
);

-- 10. ACHIEVEMENTS TABLE
create table if not exists public.achievements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text default '',
  icon text default 'star',
  created_at timestamptz default now()
);

-- 11. USER_ACHIEVEMENTS (join table)
create table if not exists public.user_achievements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  achievement_id uuid not null references public.achievements(id) on delete cascade,
  progress double precision default 0,
  unlocked boolean default false,
  updated_at timestamptz default now(),
  unique(user_id, achievement_id)
);

-- 12. NOTIFICATIONS TABLE
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  message text default '',
  type text default 'info', -- 'info', 'achievement', 'system'
  is_read boolean default false,
  created_at timestamptz default now()
);

-- =====================================================
-- INDEXES
-- =====================================================
create index if not exists idx_user_lessons_user on public.user_lessons(user_id);
create index if not exists idx_quiz_results_user on public.quiz_results(user_id);
create index if not exists idx_simulations_user on public.simulations(user_id);
create index if not exists idx_leaderboard_season on public.leaderboard(season, score desc);
create index if not exists idx_notifications_user on public.notifications(user_id, created_at desc);
create index if not exists idx_quiz_questions_difficulty on public.quiz_questions(difficulty);
create index if not exists idx_lessons_order on public.lessons(order_index);

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================
alter table public.users enable row level security;
alter table public.lessons enable row level security;
alter table public.user_lessons enable row level security;
alter table public.quiz_questions enable row level security;
alter table public.quiz_sets enable row level security;
alter table public.quiz_set_questions enable row level security;
alter table public.quiz_results enable row level security;
alter table public.simulations enable row level security;
alter table public.leaderboard enable row level security;
alter table public.achievements enable row level security;
alter table public.user_achievements enable row level security;
alter table public.notifications enable row level security;

-- Users: can read own profile, insert own profile, update own profile
create policy "Users can read own profile" on public.users for select using (auth.uid() = id);
create policy "All users can read public profiles" on public.users for select using (auth.role() = 'authenticated');
create policy "Users can insert own profile" on public.users for insert with check (auth.uid() = id);
create policy "Users can update own profile" on public.users for update using (auth.uid() = id);

-- Lessons: anyone authenticated can read
create policy "Anyone can read lessons" on public.lessons for select using (auth.role() = 'authenticated');

-- User Lessons: users manage own records
create policy "Users can read own lessons" on public.user_lessons for select using (auth.uid() = user_id);
create policy "Users can insert own lessons" on public.user_lessons for insert with check (auth.uid() = user_id);
create policy "Users can update own lessons" on public.user_lessons for update using (auth.uid() = user_id);

-- Quiz Questions: anyone authenticated can read
create policy "Anyone can read quiz questions" on public.quiz_questions for select using (auth.role() = 'authenticated');

-- Quiz Sets: anyone authenticated can read
create policy "Anyone can read quiz sets" on public.quiz_sets for select using (auth.role() = 'authenticated');

-- Quiz Set Questions: anyone authenticated can read
create policy "Anyone can read quiz set questions" on public.quiz_set_questions for select using (auth.role() = 'authenticated');

-- Quiz Results: users manage own results
create policy "Users can read own results" on public.quiz_results for select using (auth.uid() = user_id);
create policy "Users can insert own results" on public.quiz_results for insert with check (auth.uid() = user_id);

-- Simulations: users manage own simulations
create policy "Users can read own simulations" on public.simulations for select using (auth.uid() = user_id);
create policy "Users can insert own simulations" on public.simulations for insert with check (auth.uid() = user_id);
create policy "Users can update own simulations" on public.simulations for update using (auth.uid() = user_id);

-- Leaderboard: anyone authenticated can read, users manage own entries
create policy "Anyone can read leaderboard" on public.leaderboard for select using (auth.role() = 'authenticated');
create policy "Users can insert own leaderboard" on public.leaderboard for insert with check (auth.uid() = user_id);
create policy "Users can update own leaderboard" on public.leaderboard for update using (auth.uid() = user_id);

-- Achievements: anyone authenticated can read
create policy "Anyone can read achievements" on public.achievements for select using (auth.role() = 'authenticated');

-- User Achievements: users manage own achievements
create policy "Users can read own achievements" on public.user_achievements for select using (auth.uid() = user_id);
create policy "Users can insert own achievements" on public.user_achievements for insert with check (auth.uid() = user_id);
create policy "Users can update own achievements" on public.user_achievements for update using (auth.uid() = user_id);

-- Notifications: users manage own notifications
create policy "Users can read own notifications" on public.notifications for select using (auth.uid() = user_id);
create policy "Authenticated users can insert notifications" on public.notifications for insert with check (auth.role() = 'authenticated');
create policy "Users can update own notifications" on public.notifications for update using (auth.uid() = user_id);

-- Leaderboard: allow reading user info for leaderboard display
create policy "Leaderboard can read usernames" on public.users for select using (
  exists (select 1 from public.leaderboard where leaderboard.user_id = users.id)
);

-- =====================================================
-- SEED DATA: Lessons
-- =====================================================
insert into public.lessons (title, description, icon_name, duration, is_locked, content, formula, order_index) values
  ('Giá trị thặng dư là gì?', 'Khái niệm cơ bản về giá trị thặng dư trong kinh tế chính trị Mác-Lênin', 'book', '15 phút đọc', false,
   'Giá trị thặng dư (ký hiệu là m - Mehrwert) là bộ phận giá trị mới dôi ra ngoài giá trị sức lao động do công nhân làm thuê tạo ra và bị nhà tư bản chiếm không.',
   'W = C + V + m', 0),

  ('Tư bản bất biến và khả biến', 'Phân biệt hai bộ phận của tư bản: bất biến (C) và khả biến (V)', 'school', '20 phút đọc', false,
   'Tư bản bất biến (C) là bộ phận tư bản dùng để mua tư liệu sản xuất, giá trị được bảo toàn và chuyển vào sản phẩm mới. Tư bản khả biến (V) là bộ phận tư bản dùng để mua sức lao động.',
   'C: tư bản bất biến; V: tư bản khả biến', 1),

  ('Tỷ suất giá trị thặng dư', 'Cách tính và ý nghĩa của tỷ suất giá trị thặng dư', 'calculate', '15 phút đọc', false,
   'Tỷ suất giá trị thặng dư (m'') phản ánh trình độ bóc lột của nhà tư bản đối với công nhân làm thuê.',
   'm'' = m/V × 100%', 2),

  ('Hai phương pháp sản xuất GTTD', 'Giá trị thặng dư tuyệt đối và giá trị thặng dư tương đối', 'lightbulb', '25 phút đọc', false,
   'GTTD tuyệt đối: kéo dài ngày lao động. GTTD tương đối: rút ngắn thời gian lao động cần thiết nhờ nâng cao năng suất.',
   'm tuyệt đối vs m tương đối', 3),

  ('Tích lũy tư bản', 'Quá trình tái sản xuất mở rộng và tích lũy tư bản', 'trending_up', '20 phút đọc', false,
   'Tích lũy tư bản là việc chuyển một phần giá trị thặng dư thành tư bản phụ thêm để mở rộng sản xuất.',
   'Tích lũy = m → C + V bổ sung', 4),

  ('Quy luật giá trị thặng dư', 'Quy luật kinh tế cơ bản của chủ nghĩa tư bản', 'gavel', '20 phút đọc', false,
   'Quy luật giá trị thặng dư là quy luật kinh tế cơ bản của CNTB. Mục đích và động lực của sản xuất TBCN là thu được ngày càng nhiều giá trị thặng dư.',
   'Mục đích CNTB: max(m)', 5);

-- =====================================================
-- SEED DATA: Achievements
-- =====================================================
insert into public.achievements (title, description, icon) values
  ('Người mới', 'Hoàn thành bài học đầu tiên', 'star'),
  ('Học giả', 'Hoàn thành 5 bài học', 'school'),
  ('Trắc nghiệm thủ', 'Hoàn thành 10 bài trắc nghiệm', 'quiz'),
  ('Nhà kinh tế', 'Chạy 5 mô phỏng kinh tế', 'factory'),
  ('Điểm cao', 'Đạt 100% trong một bài trắc nghiệm', 'emoji_events'),
  ('Siêng năng', 'Đăng nhập 7 ngày liên tục', 'calendar_today'),
  ('Chiến binh', 'Thắng 3 trận PvP', 'military_tech'),
  ('Bậc thầy', 'Đạt level 10', 'workspace_premium');

-- =====================================================
-- SEED DATA: Quiz Questions
-- =====================================================
insert into public.quiz_questions (question, option_a, option_b, option_c, option_d, correct_answer, difficulty, topic) values
  ('Giá trị thặng dư (m) là gì?',
   'Tiền lương của công nhân',
   'Bộ phận giá trị mới dôi ra ngoài giá trị sức lao động',
   'Chi phí nguyên vật liệu',
   'Lợi nhuận ngân hàng',
   'B', 'basic', 'gia_tri_thang_du'),

  ('Công thức giá trị hàng hóa theo C.Mác là gì?',
   'W = C + V + m',
   'W = C + V',
   'W = C × V × m',
   'W = C - V + m',
   'A', 'basic', 'gia_tri_thang_du'),

  ('Tư bản bất biến (C) dùng để mua gì?',
   'Sức lao động',
   'Tư liệu sản xuất',
   'Hàng tiêu dùng',
   'Cổ phiếu',
   'B', 'basic', 'tu_ban'),

  ('Tư bản khả biến (V) dùng để mua gì?',
   'Máy móc, thiết bị',
   'Nguyên vật liệu',
   'Sức lao động',
   'Đất đai',
   'C', 'basic', 'tu_ban'),

  ('Tỷ suất giá trị thặng dư được tính bằng công thức nào?',
   'm'' = m/C × 100%',
   'm'' = m/V × 100%',
   'm'' = V/m × 100%',
   'm'' = C/m × 100%',
   'B', 'medium', 'gia_tri_thang_du'),

  ('Giá trị thặng dư tuyệt đối được tạo ra bằng cách nào?',
   'Giảm giá nguyên liệu',
   'Tăng năng suất lao động',
   'Kéo dài ngày lao động',
   'Giảm số công nhân',
   'C', 'medium', 'phuong_phap'),

  ('Giá trị thặng dư tương đối được tạo ra bằng cách nào?',
   'Kéo dài ngày lao động',
   'Rút ngắn thời gian lao động cần thiết',
   'Tăng số giờ làm thêm',
   'Giảm tiền lương',
   'B', 'medium', 'phuong_phap'),

  ('Tích lũy tư bản là gì?',
   'Gửi tiền ngân hàng',
   'Chuyển GTTD thành tư bản phụ thêm',
   'Mua cổ phiếu',
   'Tiết kiệm chi tiêu',
   'B', 'medium', 'tich_luy'),

  ('Theo C.Mác, bộ phận vốn nào dùng để mua sức lao động?',
   'Tư bản bất biến (C)',
   'Tư bản khả biến (V)',
   'Tư bản cố định',
   'Giá trị thặng dư (m)',
   'B', 'basic', 'tu_ban'),

  ('Quy luật kinh tế cơ bản của CNTB là quy luật nào?',
   'Quy luật cung cầu',
   'Quy luật giá trị',
   'Quy luật giá trị thặng dư',
   'Quy luật cạnh tranh',
   'C', 'advanced', 'quy_luat'),

  ('Nếu C = 400, V = 100, m = 100, tỷ suất giá trị thặng dư là bao nhiêu?',
   '25%',
   '50%',
   '100%',
   '200%',
   'C', 'medium', 'gia_tri_thang_du'),

  ('Nguồn gốc duy nhất của giá trị thặng dư là gì?',
   'Máy móc hiện đại',
   'Nguyên vật liệu rẻ',
   'Lao động sống của công nhân',
   'Vốn đầu tư lớn',
   'C', 'basic', 'gia_tri_thang_du'),

  ('Điều kiện để sản xuất giá trị thặng dư siêu ngạch là gì?',
   'Năng suất lao động cao hơn mức trung bình xã hội',
   'Kéo dài ngày lao động',
   'Giảm tiền lương',
   'Tăng giá bán hàng hóa',
   'A', 'advanced', 'phuong_phap'),

  ('Lợi nhuận trong CNTB thực chất là gì?',
   'Tiền lãi ngân hàng',
   'Hình thức biến tướng của giá trị thặng dư',
   'Thu nhập từ đầu tư',
   'Tiền thuê đất',
   'B', 'advanced', 'gia_tri_thang_du'),

  ('Cấu tạo hữu cơ của tư bản được biểu thị bằng tỷ lệ nào?',
   'C/V',
   'V/C',
   'm/V',
   'm/C',
   'A', 'advanced', 'tu_ban');

-- =====================================================
-- SEED DATA: Quiz Sets
-- =====================================================
insert into public.quiz_sets (title, difficulty, question_count) values
  ('Cơ bản: Giá trị thặng dư', 'basic', 5),
  ('Cơ bản: Tư bản', 'basic', 4),
  ('Trung bình: Phương pháp sản xuất', 'medium', 5),
  ('Nâng cao: Tổng hợp', 'advanced', 5);

-- Link questions to sets (run after both quiz_questions and quiz_sets are inserted)
-- Basic set 1: GTTD questions
insert into public.quiz_set_questions (set_id, question_id)
select s.id, q.id from public.quiz_sets s, public.quiz_questions q
where s.title = 'Cơ bản: Giá trị thặng dư'
  and q.topic = 'gia_tri_thang_du' and q.difficulty = 'basic';

-- Basic set 2: Tu ban questions
insert into public.quiz_set_questions (set_id, question_id)
select s.id, q.id from public.quiz_sets s, public.quiz_questions q
where s.title = 'Cơ bản: Tư bản'
  and q.topic = 'tu_ban' and q.difficulty = 'basic';

-- Medium set: mixed medium questions
insert into public.quiz_set_questions (set_id, question_id)
select s.id, q.id from public.quiz_sets s, public.quiz_questions q
where s.title = 'Trung bình: Phương pháp sản xuất'
  and q.difficulty = 'medium';

-- Advanced set: advanced questions
insert into public.quiz_set_questions (set_id, question_id)
select s.id, q.id from public.quiz_sets s, public.quiz_questions q
where s.title = 'Nâng cao: Tổng hợp'
  and q.difficulty = 'advanced';

-- =====================================================
-- FUNCTION: Auto-create user profile on auth signup
-- =====================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.users (id, email, username, avatar, xp, level)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    '',
    0,
    1
  );
  return new;
end;
$$;

-- Trigger: create profile when a new auth user signs up
create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

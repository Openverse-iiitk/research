-- Optimized RLS Policies to fix Supabase linter warnings
-- This script drops existing policies and creates optimized ones

-- Drop existing RLS policies for users table
DROP POLICY IF EXISTS "Users can view all profiles" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;

-- Drop existing RLS policies for projects table
DROP POLICY IF EXISTS "Anyone can view published projects" ON projects;
DROP POLICY IF EXISTS "Teachers can view own projects" ON projects;
DROP POLICY IF EXISTS "Teachers can create projects" ON projects;
DROP POLICY IF EXISTS "Teachers can update own projects" ON projects;
DROP POLICY IF EXISTS "Teachers can delete own projects" ON projects;

-- Drop existing RLS policies for applications table
DROP POLICY IF EXISTS "Students can view own applications" ON applications;
DROP POLICY IF EXISTS "Teachers can view applications to their projects" ON applications;
DROP POLICY IF EXISTS "Students can create applications" ON applications;
DROP POLICY IF EXISTS "Teachers can update application status" ON applications;

-- Drop existing RLS policies for blog_posts table
DROP POLICY IF EXISTS "Anyone can view published blog posts" ON blog_posts;
DROP POLICY IF EXISTS "Authors can view own blog posts" ON blog_posts;
DROP POLICY IF EXISTS "Users can create blog posts" ON blog_posts;
DROP POLICY IF EXISTS "Authors can update own blog posts" ON blog_posts;
DROP POLICY IF EXISTS "Authors can delete own blog posts" ON blog_posts;

-- Create optimized RLS policies for users table
CREATE POLICY "Users can view all profiles" ON users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING ((SELECT auth.uid())::text = id::text);
CREATE POLICY "Users can insert own profile" ON users FOR INSERT WITH CHECK ((SELECT auth.uid())::text = id::text);

-- Create optimized RLS policies for projects table (consolidated SELECT policies)
CREATE POLICY "Projects SELECT policy" ON projects FOR SELECT USING (
  status = 'active' OR author_id::text = (SELECT auth.uid())::text
);
CREATE POLICY "Teachers can create projects" ON projects FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM users WHERE id::text = (SELECT auth.uid())::text AND role = 'teacher')
  AND author_id::text = (SELECT auth.uid())::text
);
CREATE POLICY "Teachers can update own projects" ON projects FOR UPDATE USING (author_id::text = (SELECT auth.uid())::text);
CREATE POLICY "Teachers can delete own projects" ON projects FOR DELETE USING (author_id::text = (SELECT auth.uid())::text);

-- Create optimized RLS policies for applications table (consolidated SELECT policies)
CREATE POLICY "Applications SELECT policy" ON applications FOR SELECT USING (
  student_id::text = (SELECT auth.uid())::text OR
  EXISTS (SELECT 1 FROM projects WHERE id = applications.project_id AND author_id::text = (SELECT auth.uid())::text)
);
CREATE POLICY "Students can create applications" ON applications FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM users WHERE id::text = (SELECT auth.uid())::text AND role = 'student')
  AND student_id::text = (SELECT auth.uid())::text
);
CREATE POLICY "Teachers can update application status" ON applications FOR UPDATE USING (
  EXISTS (SELECT 1 FROM projects WHERE id = applications.project_id AND author_id::text = (SELECT auth.uid())::text)
);

-- Create optimized RLS policies for blog_posts table (consolidated SELECT policies)
CREATE POLICY "Blog posts SELECT policy" ON blog_posts FOR SELECT USING (
  published = true OR author_id::text = (SELECT auth.uid())::text
);
CREATE POLICY "Users can create blog posts" ON blog_posts FOR INSERT WITH CHECK (author_id::text = (SELECT auth.uid())::text);
CREATE POLICY "Authors can update own blog posts" ON blog_posts FOR UPDATE USING (author_id::text = (SELECT auth.uid())::text);
CREATE POLICY "Authors can delete own blog posts" ON blog_posts FOR DELETE USING (author_id::text = (SELECT auth.uid())::text);

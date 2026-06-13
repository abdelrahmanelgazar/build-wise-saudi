
CREATE POLICY "Users can read own project files" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'project-files' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can upload own project files" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'project-files' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete own project files" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'project-files' AND auth.uid()::text = (storage.foldername(name))[1]);

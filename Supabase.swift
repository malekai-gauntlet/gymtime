//
//  Supabase.swift
//  gymtime
//
//  Created by Malekai Mischke on 2/19/25.
//

import Supabase
import Foundation

let supabase = SupabaseClient(
  supabaseURL: URL(string: "https://kmjtprdjbeykhmypkvdv.supabase.co")!,
  supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImttanRwcmRqYmV5a2hteXBrdmR2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk5MzMwODcsImV4cCI6MjA1NTUwOTA4N30.LJ3qT8HNR30Iq1svQ13DWzydteaHm7i7_A4ZBNdJkQs"
)

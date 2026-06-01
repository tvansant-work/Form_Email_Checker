import pandas as pd
import tkinter as tk
from tkinter import filedialog, messagebox
import re
import sys

def select_file(title, filetypes):
    root = tk.Tk()
    root.withdraw() # Hide the main tkinter window
    file_path = filedialog.askopenfilename(title=title, filetypes=filetypes)
    return file_path

def save_file(title):
    root = tk.Tk()
    root.withdraw()
    file_path = filedialog.asksaveasfilename(
        title=title, 
        defaultextension=".xlsx",
        filetypes=[("Excel files", "*.xlsx")]
    )
    return file_path

def auto_extract_emails(df):
    """Scans the entire dataframe as text and extracts anything that looks like an email"""
    # Convert entire dataframe to a single string
    text_data = df.to_string()
    # Regex pattern for matching email addresses
    pattern = r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'
    emails = re.findall(pattern, text_data)
    # Return as a set of lowercase emails to remove duplicates and ensure case-insensitive matching
    return {str(email).strip().lower() for email in set(emails)}

def manual_column_selection(df):
    """Creates a simple UI to let the user pick a column from the dataframe"""
    root = tk.Tk()
    root.title("Select Email Column")
    root.geometry("400x300")
    
    selected_column = tk.StringVar()
    
    tk.Label(root, text="Select the column containing the email addresses:", pady=10).pack()
    
    listbox = tk.Listbox(root, width=50, height=10)
    listbox.pack(pady=10)
    
    for col in df.columns:
        listbox.insert(tk.END, str(col))
        
    def on_select():
        selection = listbox.curselection()
        if selection:
            selected_column.set(listbox.get(selection[0]))
            root.destroy()
        else:
            messagebox.showwarning("Warning", "Please select a column first.")

    tk.Button(root, text="Confirm Selection", command=on_select).pack(pady=10)
    
    root.mainloop()
    return selected_column.get()

def main():
    # 1. Select the Student List CSV
    student_csv_path = select_file(
        "Select the Student List CSV (SEQTA format)", 
        [("CSV files", "*.csv")]
    )
    if not student_csv_path:
        print("No student list selected. Exiting.")
        sys.exit()

    # 2. Select the Form Responses file
    responses_file_path = select_file(
        "Select the Form Responses File (Excel or CSV)", 
        [("Excel/CSV files", "*.xlsx *.xls *.csv"), ("All files", "*.*")]
    )
    if not responses_file_path:
        print("No responses file selected. Exiting.")
        sys.exit()

    # Load the Student List
    try:
        students_df = pd.read_csv(student_csv_path)
        # Ensure the required columns exist
        required_cols = ["Email", "Preferred name", "Surname", "Rollgroup"]
        missing_cols = [col for col in required_cols if col not in students_df.columns]
        if missing_cols:
            messagebox.showerror("Error", f"The student CSV is missing these required columns: {', '.join(missing_cols)}")
            sys.exit()
    except Exception as e:
        messagebox.showerror("Error", f"Failed to load Student List: {e}")
        sys.exit()

    # Load the Responses File
    try:
        if responses_file_path.endswith('.csv'):
            responses_df = pd.read_csv(responses_file_path)
        else:
            responses_df = pd.read_excel(responses_file_path)
    except Exception as e:
        messagebox.showerror("Error", f"Failed to load Responses file: {e}")
        sys.exit()

    # 3. Ask user how they want to extract emails
    root = tk.Tk()
    root.withdraw()
    auto_mode = messagebox.askyesno(
        "Email Extraction Method", 
        "Do you want to AUTOMATICALLY find all emails anywhere in the form responses?\n\n(Click 'No' to manually select a specific column)"
    )

    responded_emails = set()

    if auto_mode:
        responded_emails = auto_extract_emails(responses_df)
    else:
        email_col = manual_column_selection(responses_df)
        if not email_col:
            print("No column selected. Exiting.")
            sys.exit()
        
        # Extract emails from the chosen column and clean them up
        raw_emails = responses_df[email_col].dropna().astype(str).tolist()
        responded_emails = {email.strip().lower() for email in raw_emails if "@" in email}

    # Clean student emails for accurate matching
    students_df['Clean_Email'] = students_df['Email'].astype(str).str.strip().str.lower()
    
    # 4. Compare and find missing
    # Keep students whose clean email is NOT in the set of responded_emails
    missing_students_df = students_df[~students_df['Clean_Email'].isin(responded_emails)]
    
    # Select only the columns you requested
    final_output_df = missing_students_df[["Email", "Preferred name", "Surname", "Rollgroup"]]

    # 5. Save the output
    if final_output_df.empty:
        messagebox.showinfo("Result", "Great news! Every student in the list has responded.")
    else:
        save_path = save_file("Save the list of missing students as...")
        if save_path:
            final_output_df.to_excel(save_path, index=False)
            messagebox.showinfo(
                "Success", 
                f"Found {len(final_output_df)} students who have not responded.\nSaved to: {save_path}\n\nYou can now open this file to easily sort by Rollgroup or copy their emails."
            )
        else:
            print("Save cancelled.")

if __name__ == "__main__":
    main()
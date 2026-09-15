import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';

/**
 * Root component of the ERP application.
 * It intentionally contains no business logic: routing decides what is rendered
 * (public feature routes vs. the authenticated shell in `layout/`).
 */
@Component({
  selector: 'app-root',
  imports: [RouterOutlet],
  templateUrl: './app.component.html',
  styleUrl: './app.component.scss'
})
export class AppComponent {}
